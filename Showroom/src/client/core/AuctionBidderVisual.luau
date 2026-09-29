--!strict
-- Dedicated auction bidders: approach once, stand still, show bids.
-- Winner jumps on finish; on sell takes the pet and walks away.

local Workspace = game:GetService("Workspace")

export type Handle = {
    model: Model,
    root: BasePart,
    emotionLabel: TextLabel,
    angle: number,
    radius: number,
    approach: number,
    bobPhase: number,
    state: "approach" | "stand" | "win_jump" | "leave",
    bidText: string?,
    leaveFrom: Vector3?,
    leaveTo: Vector3?,
    leaveT: number,
    leaveDur: number,
    petAttach: BasePart?,
}

local AuctionBidderVisual = {}

local _template: Model? = nil

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

local function uprightFacing(pos: Vector3, lookTarget: Vector3): CFrame
    local flat = Vector3.new(lookTarget.X - pos.X, 0, lookTarget.Z - pos.Z)
    if flat.Magnitude < 0.05 then
        return CFrame.new(pos)
    end
    return CFrame.lookAt(pos, pos + flat.Unit)
end

local function ringPos(standCf: CFrame, angle: number, radius: number, yOff: number): Vector3
    local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local p = (standCf * CFrame.new(offset)).Position
    return Vector3.new(p.X, standCf.Position.Y + yOff, p.Z)
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

local function makeBidBillboard(adornee: BasePart): TextLabel
    local bb = Instance.new("BillboardGui")
    bb.Name = "AuctionBid"
    bb.Adornee = adornee
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(130, 30)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.MaxDistance = 70
    bb.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Name = "Bid"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
    label.BackgroundTransparency = 0.15
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 212, 38)
    label.TextStrokeTransparency = 0.5
    label.Text = "…"
    label.Parent = bb
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = label
    return label
end

local function visitorsFolder(): Folder
    local existing = Workspace:FindFirstChild("ShowroomVisitors")
    if existing and existing:IsA("Folder") then
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = "ShowroomVisitors"
    folder.Parent = Workspace
    return folder
end

function AuctionBidderVisual.spawn(standCf: CFrame, index: number, total: number): Handle?
    local template = getTemplate()
    if not template then
        return nil
    end
    local model = template:Clone()
    model.Name = `AuctionBidder_{index}`
    anchorClone(model)
    local root = ensurePrimary(model)
    if not root then
        model:Destroy()
        return nil
    end
    model.Parent = visitorsFolder()

    local angle = (index - 1) / math.max(total, 1) * math.pi * 2 + 0.2
    local radius = 5.2 + (index % 2) * 0.35
    local head = model:FindFirstChild("Head")
    local adornee = if head and head:IsA("BasePart") then head else root
    local emotionLabel = makeBidBillboard(adornee)

    local startPos = ringPos(standCf, angle, radius + 12, 0)
    model:PivotTo(uprightFacing(startPos, standCf.Position))

    return {
        model = model,
        root = root,
        emotionLabel = emotionLabel,
        angle = angle,
        radius = radius,
        approach = 0,
        bobPhase = math.random() * math.pi * 2,
        state = "approach",
        bidText = nil,
        leaveFrom = nil,
        leaveTo = nil,
        leaveT = 0,
        leaveDur = 2.4,
        petAttach = nil,
    }
end

function AuctionBidderVisual.setBid(handle: Handle, text: string?)
    handle.bidText = text
    if text and text ~= "" then
        handle.emotionLabel.Text = text
        handle.emotionLabel.TextColor3 = Color3.fromRGB(255, 212, 38)
        handle.emotionLabel.Visible = true
    else
        handle.emotionLabel.Text = "…"
        handle.emotionLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
    end
end

function AuctionBidderVisual.setWinner(handle: Handle, isWinner: boolean)
    if isWinner and handle.state ~= "leave" then
        handle.state = "win_jump"
        handle.emotionLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
    elseif not isWinner and handle.state == "win_jump" then
        handle.state = "stand"
    end
end

function AuctionBidderVisual.beginLeaveWithPet(handle: Handle, standCf: CFrame, petPart: BasePart?)
    if handle.state == "leave" then
        return
    end
    handle.state = "leave"
    local pos = handle.model:GetPivot().Position
    handle.leaveFrom = pos
    local away = (pos - standCf.Position)
    local flat = Vector3.new(away.X, 0, away.Z)
    if flat.Magnitude < 0.2 then
        flat = Vector3.new(1, 0, 0)
    end
    handle.leaveTo = pos + flat.Unit * 22 + Vector3.new(0, 0, 0)
    handle.leaveT = 0
    handle.leaveDur = 2.6

    if petPart then
        local clone = petPart:Clone()
        clone.Name = "TakenPet"
        clone.Anchored = true
        clone.CanCollide = false
        clone.Parent = handle.model
        handle.petAttach = clone
        petPart.Transparency = 1
        for _, d in petPart:GetDescendants() do
            if d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 1
            end
        end
    end
end

function AuctionBidderVisual.step(handle: Handle, standCf: CFrame, dt: number)
    local floorY = standCf.Position.Y

    if handle.state == "leave" and handle.leaveFrom and handle.leaveTo then
        handle.leaveT = math.min(1, handle.leaveT + dt / math.max(0.05, handle.leaveDur))
        local u = handle.leaveT
        local eased = u * u * (3 - 2 * u)
        local pos = handle.leaveFrom:Lerp(handle.leaveTo, eased)
        local stride = math.abs(math.sin(u * math.pi * 10)) * 0.15
        pos = Vector3.new(pos.X, floorY + stride, pos.Z)
        handle.model:PivotTo(uprightFacing(pos, handle.leaveTo))
        if handle.petAttach then
            local carry = handle.model:GetPivot() * CFrame.new(0, 1.6, -1.1)
            handle.petAttach.CFrame = carry
            handle.petAttach.Size = handle.petAttach.Size -- keep
        end
        if handle.leaveT >= 1 then
            AuctionBidderVisual.destroy(handle)
        end
        return
    end

    if handle.state == "approach" then
        handle.approach = math.min(1, handle.approach + dt / 1.15)
        if handle.approach >= 1 then
            handle.state = "stand"
        end
    end

    local a = handle.approach
    local eased = 1 - (1 - a) * (1 - a)
    local startR = handle.radius + 12
    local r = startR + (handle.radius - startR) * eased

    local jumpY = 0
    if handle.state == "win_jump" then
        jumpY = math.abs(math.sin(os.clock() * 11 + handle.bobPhase)) * 1.55
    end

    local pos = ringPos(standCf, handle.angle, r, jumpY)
    handle.model:PivotTo(uprightFacing(pos, standCf.Position))
end

function AuctionBidderVisual.destroy(handle: Handle)
    if handle.petAttach then
        handle.petAttach:Destroy()
        handle.petAttach = nil
    end
    if handle.model and handle.model.Parent then
        handle.model:Destroy()
    end
end

function AuctionBidderVisual.destroyAll(list: { Handle })
    for _, h in list do
        AuctionBidderVisual.destroy(h)
    end
    table.clear(list)
end

return AuctionBidderVisual
