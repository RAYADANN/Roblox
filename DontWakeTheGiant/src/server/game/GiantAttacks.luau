--!strict
-- Атаки великана: взмах рукой (Restless_Swat) и последовательность WAKE (Rise → Slam → Yawn).
-- Хитбокс взмаха — кисть, GetPartBoundsInBox каждые 0.05 с; ударная волна — дистанция до точки (GDD 12.3).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)

local DANGER = Color3.fromHex("#C4281C")

export type Deps = {
    rig: any,
    fxFolder: Folder,
    carry: any,
    movement: any,
    coverParams: RaycastParams,
    isCurrent: (token: number) -> boolean,
}

local GiantAttacks = {}
GiantAttacks.__index = GiantAttacks

function GiantAttacks.new(deps: Deps)
    return setmetatable({ _deps = deps, _busy = false }, GiantAttacks)
end

function GiantAttacks:busy(): boolean
    return self._busy
end

local function ease(t: number): number
    return (1 - math.cos(math.pi * math.clamp(t, 0, 1))) / 2
end

-- Плавно ведёт параметр позы; false — атаку отменили (началось WAKE).
function GiantAttacks:_animate(
    token: number,
    duration: number,
    apply: (alpha: number) -> (),
    onStep: (() -> ())?,
    stepSec: number?
): boolean
    local start = os.clock()
    local nextStep = start
    while true do
        if not self._deps.isCurrent(token) then
            return false
        end
        local t = (os.clock() - start) / duration
        apply(ease(t))
        if onStep and os.clock() >= nextStep then
            nextStep += stepSec or 0.05
            onStep()
        end
        if t >= 1 then
            return true
        end
        task.wait()
    end
end

local function dangerPart(
    parent: Instance,
    size: Vector3,
    cframe: CFrame,
    shape: Enum.PartType?
): Part
    local part = Instance.new("Part")
    part.Name = "Danger"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Color = DANGER
    part.Transparency = 0.55
    part.Size = size
    part.CFrame = cframe
    if shape then
        part.Shape = shape
    end
    part.Parent = parent
    return part
end

-- Красная тень-дуга на земле под будущим взмахом.
function GiantAttacks:_arcShadow(fromYaw: number, toYaw: number): Folder
    local folder = Instance.new("Folder")
    folder.Name = "SwatArc"
    local shoulder = self._deps.rig:shoulder()
    local segments = 8
    local inner, outer = 14, 52
    for i = 0, segments - 1 do
        local yaw = math.rad(fromYaw + (toYaw - fromYaw) * (i + 0.5) / segments)
        local dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
        local mid = Vector3.new(shoulder.X, 0.3, shoulder.Z) + dir * (inner + outer) / 2
        local width = 2 * outer * math.sin(math.rad(math.abs(toYaw - fromYaw) / segments / 2)) + 1
        dangerPart(folder, Vector3.new(width, 0.2, outer - inner), CFrame.lookAt(mid, mid + dir))
    end
    folder.Parent = self._deps.fxFolder
    return folder
end

function GiantAttacks:_catchInHand(hand: BasePart, caught: { [Player]: boolean })
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    local characters = {}
    for _, player in Players:GetPlayers() do
        if player.Character then
            table.insert(characters, player.Character)
        end
    end
    params.FilterDescendantsInstances = characters
    for _, part in
        workspace:GetPartBoundsInBox(hand.CFrame, hand.Size + Vector3.new(2, 8, 2), params)
    do
        local player = Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
        if player and not caught[player] then
            caught[player] = true
            self._deps.carry:catch(player, "Swatted by the giant!")
        end
    end
end

-- Restless_Swat: 1.2 предупреждение + 0.5 мах + 1.0 возврат.
function GiantAttacks:swat(token: number)
    if self._busy then
        return
    end
    self._busy = true
    local rig = self._deps.rig
    local arcs = GiantConfig.SWAT_ARCS
    local arc = arcs[math.random(1, #arcs)]
    local restYaw = rig.ARM_REST_YAW
    local shadow = self:_arcShadow(arc.from, arc.to)

    local ok = self:_animate(token, GiantConfig.SWAT_WARN_SEC, function(a)
        rig.armYaw = restYaw + (arc.from - restYaw) * a
        rig.armLift = GiantConfig.SWAT_RAISE_HEIGHT * a
    end)
    local caught: { [Player]: boolean } = {}
    if ok then
        local hand = rig:hand()
        ok = self:_animate(token, GiantConfig.SWAT_SWING_SEC, function(a)
            rig.armYaw = arc.from + (arc.to - arc.from) * a
            rig.armLift = GiantConfig.SWAT_RAISE_HEIGHT * (1 - math.min(1, a * 3))
        end, function()
            if hand then
                self:_catchInHand(hand, caught)
            end
        end, GiantConfig.SWAT_HITBOX_STEP_SEC)
    end
    shadow:Destroy()
    if ok then
        local yaw0 = rig.armYaw or restYaw
        ok = self:_animate(token, GiantConfig.SWAT_RETURN_SEC, function(a)
            rig.armYaw = yaw0 + (restYaw - yaw0) * a
            rig.armLift = 0
        end)
    end
    rig.armYaw = nil
    rig.armLift = 0
    self._busy = false
end

local function rootOf(player: Player): BasePart?
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Teddy_Rage: удар по последней видимой позиции вора; за укрытием — рядом с укрытием (GDD 4.3).
function GiantAttacks:_teddyTarget(thief: Player): Vector3?
    local root = rootOf(thief)
    if not root then
        return nil
    end
    local eye = self._deps.rig:eyePosition()
    local hit = workspace:Raycast(eye, root.Position - eye, self._deps.coverParams)
    if not hit then
        return root.Position
    end
    local angle = math.random() * math.pi * 2
    local r = math.random() * GiantConfig.TEDDY_COVER_SCATTER
    return Vector3.new(
        hit.Position.X + math.cos(angle) * r,
        root.Position.Y,
        hit.Position.Z + math.sin(angle) * r
    )
end

-- Цель удара: вор мишки → несущие предметы → остальные в зоне (GDD 2.3).
function GiantAttacks:_pickSlamPoint(teddyThief: Player?): Vector3
    if teddyThief then
        local carried = self._deps.carry:carried(teddyThief)
        if carried and carried.def.rarity == "Secret" then
            local point = self:_teddyTarget(teddyThief)
            if point then
                return point
            end
        end
    end
    local carriers, others = {}, {}
    for _, player in Players:GetPlayers() do
        local s = self._deps.movement:get(player)
        local root = rootOf(player)
        if s and root and s.inZone and not s.ragdolled then
            table.insert(
                if self._deps.carry:carried(player) then carriers else others,
                root.Position
            )
        end
    end
    local pool = if #carriers > 0 then carriers else others
    if #pool > 0 then
        return pool[math.random(1, #pool)]
    end
    local angle = math.random() * math.pi * 2
    local radius = 30 + math.random() * (GiantConfig.ZONE_RADIUS - 40)
    return Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
end

function GiantAttacks:_slam(point: Vector3)
    local ground = Vector3.new(point.X, point.Y - 2.8, point.Z)
    local radius = GiantConfig.SLAM_RADIUS
    local circle = dangerPart(
        self._deps.fxFolder,
        Vector3.new(0.2, radius * 2, radius * 2),
        CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.PartType.Cylinder
    )
    task.wait(GiantConfig.SLAM_WARN_SEC)
    circle:Destroy()

    local palm = dangerPart(
        self._deps.fxFolder,
        Vector3.new(14, 4, 14),
        CFrame.new(ground + Vector3.new(0, 40, 0))
    )
    palm.Material = Enum.Material.SmoothPlastic
    palm.Color = Color3.fromHex("#F2C094")
    palm.Transparency = 0
    TweenService:Create(
        palm,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { CFrame = CFrame.new(ground + Vector3.new(0, 2, 0)) }
    ):Play()
    task.wait(0.15)
    for _, player in Players:GetPlayers() do
        local root = rootOf(player)
        if root then
            local d = root.Position - ground
            if Vector2.new(d.X, d.Z).Magnitude <= radius and math.abs(d.Y) <= 12 then
                self._deps.carry:catch(player, "SLAM!")
            end
        end
    end
    task.delay(0.4, function()
        palm:Destroy()
    end)
end

-- Игроки с тела великана съезжают на землю рядом с ним: без рэгдолла, предмет остаётся в руках.
function GiantAttacks:_slideOffRiders()
    local rig = self._deps.rig
    -- Коробка торса, а не всего великана: руки и ноги раскинуты, по ним съезжать далеко.
    local torso = rig.model:FindFirstChild("Torso")
    local boxCf, boxSize = (if torso and torso:IsA("Model") then torso else rig.model):GetBoundingBox()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    -- Великана не исключаем: если сбоку лежит рука, встаём на неё, а не внутрь неё.
    local exclude: { Instance } = { self._deps.fxFolder }
    for _, player in Players:GetPlayers() do
        if player.Character then
            table.insert(exclude, player.Character)
        end
    end
    params.FilterDescendantsInstances = exclude
    for _, player in Players:GetPlayers() do
        local s = self._deps.movement:get(player)
        local root = rootOf(player)
        if s and root and s.floorPart and s.floorPart:IsDescendantOf(rig.model) then
            local offset = boxCf:PointToObjectSpace(root.Position)
            -- Съезжаем вбок, через ближнюю длинную грань коробки великана (он лежит вдоль длинной оси).
            local alongX = boxSize.X < boxSize.Z
            local side = math.sign(if alongX then offset.X else offset.Z)
            side = if side == 0 then 1 else side
            local exitLocal = if alongX
                then Vector3.new(side * (boxSize.X / 2 + GiantConfig.SLIDE_OFF_MARGIN), 0, offset.Z)
                else Vector3.new(
                    offset.X,
                    0,
                    side * (boxSize.Z / 2 + GiantConfig.SLIDE_OFF_MARGIN)
                )
            local exit = boxCf:PointToWorldSpace(exitLocal)
            local hit =
                workspace:Raycast(Vector3.new(exit.X, 200, exit.Z), Vector3.new(0, -400, 0), params)
            local ground = if hit then hit.Position else Vector3.new(exit.X, 0, exit.Z)
            self._deps.movement:exempt(player, 2)
            player.Character:PivotTo(
                CFrame.new(ground + Vector3.new(0, 3, 0)) * root.CFrame.Rotation
            )
        end
    end
end

-- WAKE: тряска живота 1 с → подъём → удары → зевок. Teddy: фора 3 с без ударов → погоня 15 с.
-- Во время всего WAKE шум заморожен на 100.
function GiantAttacks:wakeSequence(token: number, teddyThief: Player?)
    local rig = self._deps.rig
    rig.armYaw = nil
    rig.armLift = 0

    if not teddyThief then
        rig.shake = GiantConfig.WAKE_SHAKE_AMPLITUDE
        task.wait(GiantConfig.WAKE_SHAKE_SEC)
        rig.shake = 0
    end
    self:_slideOffRiders()
    -- Teddy_Wake: великан садится и трёт глаза всю фору вора, никого не ловит.
    local riseSec = if teddyThief
        then GiantConfig.TEDDY_HEADSTART_SEC
        else GiantConfig.WAKE_RISE_SEC
    self:_animate(token, riseSec, function(a)
        rig.riseDeg = GiantConfig.WAKE_RISE_DEG * a
    end)

    local duration = if teddyThief then GiantConfig.TEDDY_RAGE_SEC else GiantConfig.WAKE_SLAM_SEC
    local elapsed = 0
    while elapsed < duration do
        local point = self:_pickSlamPoint(teddyThief)
        task.spawn(self._slam, self, point)
        task.wait(GiantConfig.SLAM_INTERVAL_SEC)
        elapsed += GiantConfig.SLAM_INTERVAL_SEC
    end

    self:_animate(token, GiantConfig.WAKE_YAWN_SEC, function(a)
        rig.riseDeg = GiantConfig.WAKE_RISE_DEG * (1 - a)
    end)
    rig.riseDeg = 0
    rig.lidL, rig.lidR = 0, 0
end

return GiantAttacks
