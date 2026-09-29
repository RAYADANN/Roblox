--!strict
-- Noob visitors: approach, linger, fidget, roam. Recovers if a stand disappears (e.g. auction).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NpcEmotionDatabase = require(ReplicatedStorage.shared.data.NpcEmotionDatabase)

export type StandInfo = {
    key: string,
    cf: CFrame, -- floor anchor for the stand footprint (not the floating item)
    lookAt: Vector3?, -- where visitors face; defaults above cf
    rarity: string,
    celebrate: boolean,
    celebrateKind: string,
    open: boolean, -- false while auctioning: visible for recovery, not a wander target
}

export type NpcHandle = {
    model: Model,
    root: BasePart,
    emotionLabel: TextLabel,
    homeKey: string,
    viewKey: string,
    rarity: string,
    angle: number,
    radius: number,
    approach: number,
    bobPhase: number,
    lookPhase: number,
    swayAmp: number,
    swayFreq: number,
    tempo: number,
    celebrating: boolean,
    celebrateKind: string,
    bidText: string?,
    isWanderer: boolean,
    curiosity: number, -- 0..1; how likely to chase mutate/evolve spectacle
    rushing: boolean,
    hotDecisionKey: string?, -- celebrate stand key we already rolled for
    willChaseHot: boolean,
    state: "approach" | "inspect" | "walk" | "shuffle" | "leave",
    emotionTimer: number,
    wanderTimer: number,
    fidgetTimer: number,
    lookAwayTimer: number,
    lookAway: boolean,
    bornAt: number,
    lifetime: number,
    walkFrom: Vector3?,
    walkTo: Vector3?,
    walkLook: Vector3?,
    walkT: number,
    walkDur: number,
    nextAngle: number?,
    nextRadius: number?,
    nextKey: string?,
    nextRarity: string?,
    shuffleFromAngle: number?,
    shuffleToAngle: number?,
    shuffleFromRadius: number?,
    shuffleToRadius: number?,
    leaveFrom: Vector3?,
    leaveTo: Vector3?,
}

local NpcCrowdVisual = {}

local _template: Model? = nil
local _visitorsFolder: Folder? = nil
local _footLift: number? = nil

local WALK_SPEED = 6.8
local RUN_SPEED = 17
local EMOTION_MIN = 1.6
local EMOTION_MAX = 5.5
local MIN_SEP_STUDS = 1.65
local RING_RADII: { number } = { 4.85, 5.65, 6.45 }
local TWO_PI = math.pi * 2
-- R6 Noob: HumanoidRootPart sits ~3 studs above feet (HipHeight is 0).
local DEFAULT_FOOT_LIFT = 3

local RARITY_EMOTE_COLOR: { [string]: Color3 } = {
    common = Color3.fromRGB(190, 190, 200),
    uncommon = Color3.fromRGB(90, 210, 130),
    rare = Color3.fromRGB(90, 150, 255),
    epic = Color3.fromRGB(200, 120, 255),
    legendary = Color3.fromRGB(255, 190, 60),
}

local function getTemplate(): Model?
    if _template and _template.Parent then
        return _template
    end
    local n = Workspace:FindFirstChild("Noob")
    if n and n:IsA("Model") then
        _template = n
        return n
    end
    return nil
end

function NpcCrowdVisual.visitorsFolder(): Folder
    if _visitorsFolder and _visitorsFolder.Parent then
        return _visitorsFolder
    end
    local existing = Workspace:FindFirstChild("ShowroomVisitors")
    if existing and existing:IsA("Folder") then
        _visitorsFolder = existing
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = "ShowroomVisitors"
    folder.Parent = Workspace
    _visitorsFolder = folder
    return folder
end

local function uprightFacing(pos: Vector3, lookTarget: Vector3): CFrame
    local flat = Vector3.new(lookTarget.X - pos.X, 0, lookTarget.Z - pos.Z)
    if flat.Magnitude < 0.05 then
        return CFrame.new(pos)
    end
    return CFrame.lookAt(pos, pos + flat.Unit)
end

-- Pivot places PrimaryPart (HRP); stand cf is floor — lift so feet sit on ground.
local function footLift(): number
    if _footLift ~= nil then
        return _footLift
    end
    local template = getTemplate()
    if not template then
        return DEFAULT_FOOT_LIFT
    end
    local root = template:FindFirstChild("HumanoidRootPart")
    if not (root and root:IsA("BasePart")) then
        _footLift = DEFAULT_FOOT_LIFT
        return _footLift
    end
    local cf, size = template:GetBoundingBox()
    local bottom = cf.Position.Y - size.Y * 0.5
    _footLift = math.max(1, root.Position.Y - bottom)
    return _footLift
end

local function standRootY(standCf: CFrame): number
    return standCf.Position.Y + footLift()
end

local function ringWorldPos(standCf: CFrame, angle: number, radius: number): Vector3
    local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local p = (standCf * CFrame.new(offset)).Position
    return Vector3.new(p.X, standRootY(standCf), p.Z)
end

local function randRange(lo: number, hi: number): number
    return lo + math.random() * (hi - lo)
end

local function anchorClone(model: Model)
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanTouch = false
            d.CanQuery = false
            d.Massless = true
        elseif d:IsA("BaseScript") or d:IsA("Highlight") then
            d:Destroy()
        end
    end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.AutoRotate = false
        hum.PlatformStand = true
    end
end

local function ensurePrimary(model: Model): BasePart?
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        model.PrimaryPart = root
        return root
    end
    local torso = model:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") then
        model.PrimaryPart = torso
        return torso
    end
    return model.PrimaryPart
end

local function makeEmotionBillboard(adornee: BasePart, text: string, color: Color3): TextLabel
    local bb = Instance.new("BillboardGui")
    bb.Name = "NpcEmotion"
    bb.Adornee = adornee
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(90, 28)
    bb.StudsOffset = Vector3.new(0, 2.4, 0)
    bb.MaxDistance = 60
    bb.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Name = "Emotion"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
    label.BackgroundTransparency = 0.2
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.5
    label.Text = text
    label.Parent = bb
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = label
    return label
end

local function applyEmotion(handle: NpcHandle, text: string, color: Color3)
    handle.emotionLabel.Text = text
    handle.emotionLabel.TextColor3 = color
    local bb = handle.emotionLabel.Parent
    if bb and bb:IsA("BillboardGui") then
        bb.Size = if #text > 12 then UDim2.fromOffset(140, 32) else UDim2.fromOffset(90, 28)
    end
end

local function refreshEmotion(handle: NpcHandle)
    if handle.bidText and handle.bidText ~= "" then
        applyEmotion(handle, handle.bidText, Color3.fromRGB(255, 212, 38))
        handle.emotionTimer = randRange(EMOTION_MIN, EMOTION_MAX)
        return
    end
    if handle.celebrating then
        if handle.celebrateKind == "evolve" then
            applyEmotion(
                handle,
                NpcEmotionDatabase.pickEvolve(math.random()),
                Color3.fromRGB(255, 200, 60)
            )
        else
            applyEmotion(
                handle,
                NpcEmotionDatabase.pickCelebrate(math.random()),
                Color3.fromRGB(255, 220, 80)
            )
        end
    elseif handle.rushing or handle.state == "walk" then
        if handle.rushing then
            applyEmotion(
                handle,
                NpcEmotionDatabase.pickCelebrate(math.random()),
                Color3.fromRGB(255, 170, 90)
            )
        else
            applyEmotion(
                handle,
                NpcEmotionDatabase.pickWalk(math.random()),
                Color3.fromRGB(200, 210, 230)
            )
        end
    else
        local color = RARITY_EMOTE_COLOR[handle.rarity] or RARITY_EMOTE_COLOR.common
        applyEmotion(handle, NpcEmotionDatabase.pick(handle.rarity, math.random()), color)
    end
    handle.emotionTimer = randRange(EMOTION_MIN, EMOTION_MAX) * handle.tempo
end

local function findStand(stands: { StandInfo }, key: string): StandInfo?
    for _, s in stands do
        if s.key == key then
            return s
        end
    end
    return nil
end

local function pickOpenStand(stands: { StandInfo }, preferKey: string?): StandInfo?
    if preferKey then
        local preferred = findStand(stands, preferKey)
        if preferred and preferred.open then
            return preferred
        end
    end
    local open: { StandInfo } = {}
    for _, s in stands do
        if s.open then
            table.insert(open, s)
        end
    end
    if #open == 0 then
        return if #stands > 0 then stands[math.random(1, #stands)] else nil
    end
    return open[math.random(1, #open)]
end

local function recoverView(handle: NpcHandle, stands: { StandInfo }): StandInfo?
    local view = pickOpenStand(stands, handle.homeKey) or pickOpenStand(stands, nil)
    if not view then
        return nil
    end
    handle.viewKey = view.key
    handle.rarity = view.rarity
    handle.state = "inspect"
    handle.approach = 1
    handle.rushing = false
    handle.celebrating = false
    handle.celebrateKind = ""
    handle.walkFrom = nil
    handle.walkTo = nil
    handle.nextKey = nil
    handle.angle = math.random() * math.pi * 2
    handle.radius = randRange(5.0, 6.4)
    handle.wanderTimer = randRange(2.0, 6.0) * handle.tempo
    handle.fidgetTimer = randRange(1.2, 3.5)
    refreshEmotion(handle)
    return view
end

local function angDist(a: number, b: number): number
    local d = (a - b) % TWO_PI
    if d > math.pi then
        d = TWO_PI - d
    end
    return d
end

local function poseClearance(
    angle: number,
    radius: number,
    peers: { NpcHandle },
    viewKey: string,
    ignore: NpcHandle?
): number
    local best = 100
    for _, peer in peers do
        if
            peer ~= ignore
            and NpcCrowdVisual.isAlive(peer)
            and not NpcCrowdVisual.isLeaving(peer)
            and peer.viewKey == viewKey
        then
            local arc = angDist(angle, peer.angle) * ((radius + peer.radius) * 0.5)
            local rad = math.abs(radius - peer.radius)
            local d = math.sqrt(arc * arc + rad * rad * 2.2)
            if d < best then
                best = d
            end
        end
    end
    return best
end

function NpcCrowdVisual.pickFreePose(
    peers: { NpcHandle },
    viewKey: string,
    ignore: NpcHandle?
): (number, number)
    local bestAngle = math.random() * TWO_PI
    local bestRadius = RING_RADII[2]
    local bestScore = -1.0
    local n = 0
    for _, peer in peers do
        if
            peer ~= ignore
            and NpcCrowdVisual.isAlive(peer)
            and not NpcCrowdVisual.isLeaving(peer)
            and peer.viewKey == viewKey
        then
            n += 1
        end
    end
    local attempts = math.clamp(18 + n * 3, 18, 40)
    for i = 1, attempts do
        local radius = RING_RADII[((i - 1) % #RING_RADII) + 1]
        local angle = if i <= n + 3
            then ((i - 1) / math.max(n + 3, 1)) * TWO_PI + randRange(-0.08, 0.08)
            else math.random() * TWO_PI
        local score = poseClearance(angle, radius, peers, viewKey, ignore)
        -- Prefer mid ring slightly.
        score += if radius == RING_RADII[2] then 0.08 else 0
        if score > bestScore then
            bestScore = score
            bestAngle = angle
            bestRadius = radius
        end
        if score >= MIN_SEP_STUDS * 1.15 then
            break
        end
    end
    return bestAngle, bestRadius
end

local function softSeparate(handle: NpcHandle, peers: { NpcHandle }, dt: number)
    if handle.state ~= "inspect" and handle.state ~= "approach" then
        return
    end
    local pushA = 0
    local pushR = 0
    for _, peer in peers do
        if
            peer ~= handle
            and NpcCrowdVisual.isAlive(peer)
            and not NpcCrowdVisual.isLeaving(peer)
            and peer.viewKey == handle.viewKey
            and (peer.state == "inspect" or peer.state == "approach" or peer.state == "shuffle")
        then
            local arc = angDist(handle.angle, peer.angle) * ((handle.radius + peer.radius) * 0.5)
            local rad = math.abs(handle.radius - peer.radius)
            local d = math.sqrt(arc * arc + rad * rad * 2.2)
            if d < MIN_SEP_STUDS and d > 1e-3 then
                local strength = (MIN_SEP_STUDS - d) / MIN_SEP_STUDS
                local sign = if ((handle.angle - peer.angle + math.pi) % TWO_PI) > math.pi
                    then -1
                    else 1
                pushA += sign * strength * 0.55
                if handle.radius <= peer.radius then
                    pushR -= strength * 0.35
                else
                    pushR += strength * 0.35
                end
            end
        end
    end
    local damp = math.clamp(dt * 9, 0, 1)
    handle.angle += pushA * damp
    handle.radius =
        math.clamp(handle.radius + pushR * damp, RING_RADII[1] - 0.15, RING_RADII[3] + 0.25)
end

local function findHotEvent(stands: { StandInfo }): StandInfo?
    local mutateHot: StandInfo? = nil
    for _, s in stands do
        if s.open and s.celebrate and s.celebrateKind == "evolve" then
            return s
        end
        if s.open and s.celebrate and s.celebrateKind == "mutate" and mutateHot == nil then
            mutateHot = s
        end
    end
    return mutateHot
end

local function pickWanderTarget(handle: NpcHandle, stands: { StandInfo }): StandInfo?
    local options: { StandInfo } = {}
    for _, s in stands do
        if s.open and s.key ~= handle.viewKey then
            table.insert(options, s)
        end
    end
    if #options == 0 then
        return nil
    end
    -- Slight bias toward home so crowds don't all drain one stand.
    if math.random() < 0.22 then
        local home = findStand(stands, handle.homeKey)
        if home and home.open and home.key ~= handle.viewKey then
            return home
        end
    end
    return options[math.random(1, #options)]
end

local function beginTravel(
    handle: NpcHandle,
    fromPos: Vector3,
    target: StandInfo,
    speed: number,
    rushing: boolean,
    peers: { NpcHandle }
)
    local nextAngle, nextRadius = NpcCrowdVisual.pickFreePose(peers, target.key, handle)
    local dest = ringWorldPos(target.cf, nextAngle, nextRadius)
    local dist = (dest - fromPos).Magnitude
    local speedJitter = speed * randRange(0.85, 1.15)
    handle.state = "walk"
    handle.rushing = rushing
    handle.walkFrom = Vector3.new(fromPos.X, standRootY(target.cf), fromPos.Z)
    handle.walkTo = dest
    handle.walkLook = target.lookAt or (target.cf.Position + Vector3.new(0, 2.2, 0))
    handle.walkT = 0
    handle.walkDur =
        math.clamp(dist / speedJitter, if rushing then 0.35 else 0.75, if rushing then 2.4 else 5.2)
    handle.nextAngle = nextAngle
    handle.nextRadius = nextRadius
    handle.nextKey = target.key
    handle.nextRarity = target.rarity
    refreshEmotion(handle)
end

local function beginShuffle(handle: NpcHandle, peers: { NpcHandle })
    local toAngle, toRadius = NpcCrowdVisual.pickFreePose(peers, handle.viewKey, handle)
    -- Keep shuffle local: blend toward free pose instead of teleport intent.
    handle.state = "shuffle"
    handle.shuffleFromAngle = handle.angle
    handle.shuffleToAngle = handle.angle
        + math.clamp(((toAngle - handle.angle + math.pi) % TWO_PI) - math.pi, -0.7, 0.7)
    handle.shuffleFromRadius = handle.radius
    handle.shuffleToRadius = math.clamp(toRadius, RING_RADII[1], RING_RADII[3])
    handle.walkT = 0
    handle.walkDur = randRange(0.55, 1.35) * handle.tempo
    refreshEmotion(handle)
end

function NpcCrowdVisual.spawn(
    standCf: CFrame,
    index: number,
    _total: number,
    rarity: string,
    slotKey: string,
    peers: { NpcHandle }?
): NpcHandle?
    local template = getTemplate()
    if not template then
        return nil
    end
    local model = template:Clone()
    model.Name = `Visitor_{slotKey}_{index}`
    anchorClone(model)
    local root = ensurePrimary(model)
    if not root then
        model:Destroy()
        return nil
    end
    model.Parent = NpcCrowdVisual.visitorsFolder()

    local peerList = peers or {}
    local angle, radius = NpcCrowdVisual.pickFreePose(peerList, slotKey, nil)
    local isWanderer = math.random() < 0.55
    local tempo = randRange(0.75, 1.35)
    local curiosity = randRange(0.15, 1.0)

    local head = model:FindFirstChild("Head")
    local adornee = if head and head:IsA("BasePart") then head else root
    local color = RARITY_EMOTE_COLOR[rarity] or RARITY_EMOTE_COLOR.common
    local emotionLabel =
        makeEmotionBillboard(adornee, NpcEmotionDatabase.pick(rarity, math.random()), color)

    local startPos = ringWorldPos(standCf, angle, radius + randRange(8, 14))
    model:PivotTo(uprightFacing(startPos, standCf.Position))

    return {
        model = model,
        root = root,
        emotionLabel = emotionLabel,
        homeKey = slotKey,
        viewKey = slotKey,
        rarity = rarity,
        angle = angle,
        radius = radius,
        approach = 0,
        bobPhase = math.random() * math.pi * 2,
        lookPhase = math.random() * math.pi * 2,
        swayAmp = randRange(0.08, 0.22),
        swayFreq = randRange(0.7, 1.6),
        tempo = tempo,
        celebrating = false,
        celebrateKind = "",
        bidText = nil,
        isWanderer = isWanderer,
        curiosity = curiosity,
        rushing = false,
        hotDecisionKey = nil,
        willChaseHot = false,
        state = "approach",
        emotionTimer = randRange(0.8, 2.5),
        wanderTimer = randRange(2.5, 8.0) * tempo,
        fidgetTimer = randRange(1.0, 4.0),
        lookAwayTimer = randRange(2.0, 6.0),
        lookAway = false,
        bornAt = os.clock(),
        lifetime = randRange(14, 32),
        walkFrom = nil,
        walkTo = nil,
        walkLook = nil,
        walkT = 0,
        walkDur = 1,
        nextAngle = nil,
        nextRadius = nil,
        nextKey = nil,
        nextRarity = nil,
        shuffleFromAngle = nil,
        shuffleToAngle = nil,
        shuffleFromRadius = nil,
        shuffleToRadius = nil,
        leaveFrom = nil,
        leaveTo = nil,
    }
end

function NpcCrowdVisual.setCelebrating(handle: NpcHandle, celebrating: boolean, kind: string)
    local nextKind = if celebrating then kind else ""
    if handle.celebrating == celebrating and handle.celebrateKind == nextKind then
        return
    end
    handle.celebrating = celebrating
    handle.celebrateKind = nextKind
    if not (handle.bidText and handle.bidText ~= "") then
        refreshEmotion(handle)
    end
end

function NpcCrowdVisual.setBidText(handle: NpcHandle, text: string?)
    local nextText = if text and text ~= "" then text else nil
    if handle.bidText == nextText then
        return
    end
    handle.bidText = nextText
    refreshEmotion(handle)
end

function NpcCrowdVisual.isLeaving(handle: NpcHandle): boolean
    return handle.state == "leave"
end

function NpcCrowdVisual.isAlive(handle: NpcHandle): boolean
    return handle.model ~= nil and handle.model.Parent ~= nil
end

function NpcCrowdVisual.shouldRetire(handle: NpcHandle): boolean
    if handle.state == "leave" or handle.celebrating or handle.rushing then
        return false
    end
    if handle.state == "approach" or handle.state == "walk" then
        return false
    end
    return (os.clock() - handle.bornAt) >= handle.lifetime
end

function NpcCrowdVisual.beginLeave(handle: NpcHandle, standCf: CFrame)
    if handle.state == "leave" then
        return
    end
    local pos = handle.model:GetPivot().Position
    local away = Vector3.new(pos.X - standCf.Position.X, 0, pos.Z - standCf.Position.Z)
    if away.Magnitude < 0.2 then
        away = Vector3.new(math.cos(handle.angle), 0, math.sin(handle.angle))
    end
    handle.state = "leave"
    handle.rushing = false
    handle.celebrating = false
    handle.leaveFrom = pos
    handle.leaveTo = pos + away.Unit * randRange(16, 26)
    handle.walkT = 0
    handle.walkDur = randRange(1.6, 2.8) * handle.tempo
    applyEmotion(handle, NpcEmotionDatabase.pickWalk(math.random()), Color3.fromRGB(190, 200, 220))
end

function NpcCrowdVisual.step(
    handle: NpcHandle,
    stands: { StandInfo },
    peers: { NpcHandle },
    dt: number
)
    if not NpcCrowdVisual.isAlive(handle) then
        return
    end

    if handle.state == "leave" and handle.leaveFrom and handle.leaveTo then
        handle.walkT = math.min(1, handle.walkT + dt / math.max(0.05, handle.walkDur))
        local u = handle.walkT
        local eased = u * u * (3 - 2 * u)
        local pos = handle.leaveFrom:Lerp(handle.leaveTo, eased)
        local stride = math.abs(math.sin(u * math.pi * 9 + handle.bobPhase)) * 0.12
        pos = Vector3.new(pos.X, handle.leaveFrom.Y + stride, pos.Z)
        handle.model:PivotTo(uprightFacing(pos, handle.leaveTo))
        if handle.walkT >= 1 then
            NpcCrowdVisual.destroy(handle)
        end
        return
    end

    if #stands == 0 then
        return
    end

    local view = findStand(stands, handle.viewKey)
    if not view or (not view.open and handle.state ~= "walk") then
        view = recoverView(handle, stands)
        if not view then
            return
        end
        local a, r = NpcCrowdVisual.pickFreePose(peers, view.key, handle)
        handle.angle = a
        handle.radius = r
    end

    handle.emotionTimer -= dt
    if handle.emotionTimer <= 0 then
        if not (handle.bidText and handle.bidText ~= "") then
            refreshEmotion(handle)
        else
            handle.emotionTimer = randRange(EMOTION_MIN, EMOTION_MAX)
        end
    end

    local hot = findHotEvent(stands)
    if hot then
        if handle.hotDecisionKey ~= hot.key then
            handle.hotDecisionKey = hot.key
            local baseChance = if hot.celebrateKind == "evolve" then 0.42 else 0.26
            handle.willChaseHot = math.random() < (baseChance * (0.45 + 0.55 * handle.curiosity))
        end
        if
            handle.willChaseHot
            and handle.viewKey ~= hot.key
            and handle.nextKey ~= hot.key
            and handle.state ~= "walk"
            and handle.state ~= "leave"
        then
            local pivot = handle.model:GetPivot().Position
            beginTravel(handle, pivot, hot, RUN_SPEED, true, peers)
        elseif hot and handle.viewKey == hot.key and handle.state ~= "walk" then
            handle.rushing = false
        end
    else
        handle.hotDecisionKey = nil
        handle.willChaseHot = false
    end

    local celebrateHere = view.celebrate and view.open
    local celebrateKind = if celebrateHere then view.celebrateKind else ""
    if handle.rushing and hot and handle.willChaseHot then
        NpcCrowdVisual.setCelebrating(handle, true, hot.celebrateKind)
    else
        NpcCrowdVisual.setCelebrating(handle, celebrateHere, celebrateKind)
    end

    if handle.state == "walk" and handle.walkFrom and handle.walkTo and handle.walkLook then
        handle.walkT = math.min(1, handle.walkT + dt / math.max(0.05, handle.walkDur))
        local u = handle.walkT
        local eased = u * u * (3 - 2 * u)
        -- Soft lateral drift so paths aren't ruler-straight.
        local lateral = math.sin(u * math.pi) * (if handle.rushing then 0.35 else 0.9)
        local along = handle.walkFrom:Lerp(handle.walkTo, eased)
        local dir = handle.walkTo - handle.walkFrom
        local side = Vector3.new(-dir.Z, 0, dir.X)
        if side.Magnitude > 0.05 then
            side = side.Unit * lateral
        else
            side = Vector3.zero
        end
        local strideFreq = if handle.rushing then 13 else randRange(5.2, 7.0)
        local strideAmp = if handle.rushing then 0.26 else 0.11
        local stride = math.abs(math.sin(u * math.pi * strideFreq + handle.bobPhase)) * strideAmp
        local floorY = handle.walkTo.Y
        local pos = Vector3.new(along.X + side.X, floorY + stride, along.Z + side.Z)
        local ahead = along + dir.Unit * 1.2 + side
        handle.model:PivotTo(uprightFacing(pos, ahead))

        if handle.walkT >= 1 then
            local arrivedKey = handle.nextKey or handle.viewKey
            local arrived = findStand(stands, arrivedKey)
            if not arrived or not arrived.open then
                recoverView(handle, stands)
            else
                handle.viewKey = arrived.key
                handle.rarity = arrived.rarity
                handle.angle = handle.nextAngle or handle.angle
                handle.radius = handle.nextRadius or handle.radius
                -- Re-slot on arrival so we don't stack on a popular angle.
                local a, r = NpcCrowdVisual.pickFreePose(peers, handle.viewKey, handle)
                handle.angle = a
                handle.radius = r
                handle.state = "inspect"
                handle.approach = 1
                handle.rushing = false
                handle.wanderTimer = randRange(2.2, 9.0) * handle.tempo
                handle.fidgetTimer = randRange(0.8, 2.8)
                handle.walkFrom = nil
                handle.walkTo = nil
                handle.nextKey = nil
                refreshEmotion(handle)
            end
        end
        return
    end

    if
        handle.state == "shuffle"
        and handle.shuffleFromAngle
        and handle.shuffleToAngle
        and handle.shuffleFromRadius
        and handle.shuffleToRadius
    then
        handle.walkT = math.min(1, handle.walkT + dt / math.max(0.05, handle.walkDur))
        local u = handle.walkT
        local eased = u * u * (3 - 2 * u)
        handle.angle = handle.shuffleFromAngle
            + (handle.shuffleToAngle - handle.shuffleFromAngle) * eased
        handle.radius = handle.shuffleFromRadius
            + (handle.shuffleToRadius - handle.shuffleFromRadius) * eased
        local stride = math.abs(math.sin(u * math.pi * 6 + handle.bobPhase)) * 0.08
        local pos = ringWorldPos(view.cf, handle.angle, handle.radius)
        pos = Vector3.new(pos.X, standRootY(view.cf) + stride, pos.Z)
        local gaze = view.lookAt or (view.cf.Position + Vector3.new(0, 2.2, 0))
        handle.model:PivotTo(uprightFacing(pos, gaze))
        if handle.walkT >= 1 then
            handle.state = "inspect"
            handle.fidgetTimer = randRange(1.2, 3.8) * handle.tempo
        end
        return
    end

    if handle.state == "approach" then
        handle.approach = math.min(1, handle.approach + dt / (1.35 * handle.tempo))
        if handle.approach >= 1 then
            handle.state = "inspect"
            handle.wanderTimer = randRange(2.0, 7.5) * handle.tempo
            handle.fidgetTimer = randRange(0.6, 2.5)
        end
    end

    softSeparate(handle, peers, dt)

    local a = handle.approach
    local eased = 1 - (1 - a) * (1 - a)
    local startR = handle.radius + 10
    local r = startR + (handle.radius - startR) * eased
    local floorY = standRootY(view.cf)
    local clock = os.clock()

    local examineShift = 0
    if handle.state == "inspect" then
        examineShift = math.sin(clock * handle.swayFreq + handle.lookPhase) * handle.swayAmp
        if handle.celebrating then
            examineShift *= 1.8
        end
    end

    local jumpY = 0
    if handle.celebrating then
        local amp = if handle.celebrateKind == "evolve" then 1.7 else 1.35
        local freq = if handle.celebrateKind == "evolve" then 11.5 else 10.2
        jumpY = math.abs(math.sin(clock * freq + handle.bobPhase)) * amp
    else
        -- Soft weight shift — alive, not dancing.
        jumpY = math.sin(clock * (1.4 + handle.swayFreq * 0.35) + handle.bobPhase) * 0.045
    end

    local lookTarget = view.lookAt or (view.cf.Position + Vector3.new(0, 2.2, 0))
    if handle.state == "inspect" then
        handle.lookAwayTimer -= dt
        if handle.lookAwayTimer <= 0 then
            handle.lookAway = not handle.lookAway
            handle.lookAwayTimer = if handle.lookAway
                then randRange(0.45, 1.3)
                else randRange(2.2, 6.5) * handle.tempo
        end
    end

    local offset = Vector3.new(
        math.cos(handle.angle) * r + math.cos(handle.angle + math.pi / 2) * examineShift,
        jumpY,
        math.sin(handle.angle) * r + math.sin(handle.angle + math.pi / 2) * examineShift
    )
    local pos = (view.cf * CFrame.new(offset)).Position
    pos = Vector3.new(pos.X, floorY + jumpY, pos.Z)
    if handle.lookAway and handle.state == "inspect" and not handle.celebrating then
        local side = Vector3.new(math.cos(handle.angle + 1.15), 0, math.sin(handle.angle + 1.15))
        lookTarget = pos + side * 5
    end
    handle.model:PivotTo(uprightFacing(pos, lookTarget))

    if handle.state == "inspect" and not handle.celebrating and not hot then
        handle.fidgetTimer -= dt
        if handle.fidgetTimer <= 0 then
            local roll = math.random()
            if roll < 0.55 then
                beginShuffle(handle, peers)
            else
                handle.fidgetTimer = randRange(1.4, 4.2) * handle.tempo
                handle.radius =
                    math.clamp(handle.radius + randRange(-0.2, 0.25), RING_RADII[1], RING_RADII[3])
            end
        end

        if handle.isWanderer then
            handle.wanderTimer -= dt
            if handle.wanderTimer <= 0 then
                local target = pickWanderTarget(handle, stands)
                if target then
                    beginTravel(handle, pos, target, WALK_SPEED * handle.tempo, false, peers)
                else
                    beginShuffle(handle, peers)
                    handle.wanderTimer = randRange(3.0, 8.0) * handle.tempo
                end
            end
        end
    end
end

function NpcCrowdVisual.destroy(handle: NpcHandle)
    handle.model:Destroy()
end

return NpcCrowdVisual
