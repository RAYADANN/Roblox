--!strict
-- World cosmetics:
-- 1) Player attribute slots (pets/aura — all clients render).
-- 2) Held inventory egg welded to RightHand (server Model → replicates).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ExhibitLogic = require(ReplicatedStorage.shared.util.ExhibitLogic)
local PlayerAttributeSync = require(ReplicatedStorage.shared.util.PlayerAttributeSync)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)

export type Slot = PlayerAttributeSync.Slot
type PlayerData = PlayerDataModule.PlayerData

local WorldCosmeticPublisher = {}

local HELD_NAME = "HeldEgg"
local EGGS_FOLDER = "Eggs"
local FX_PART_NAME = "Part"
local SKIP = { noname = true }
-- Same visualScale as BuyPlace pads (progress=0); no extra shrink.
local GRIP = CFrame.new(0, -0.12, -0.42) * CFrame.Angles(math.rad(-12), math.rad(90), 0)

type HeldWant = {
    templateId: string,
    sizeId: string,
    mutations: { string },
}

local _heldWant: { [Player]: HeldWant? } = {}
local _heldStarted = false

function WorldCosmeticPublisher.publish(player: Player, slots: { Slot })
    if not player.Parent then
        return
    end
    player:SetAttribute(PlayerAttributeSync.ATTRIBUTE, PlayerAttributeSync.encode(slots))
end

function WorldCosmeticPublisher.clear(player: Player)
    if not player.Parent then
        return
    end
    player:SetAttribute(PlayerAttributeSync.ATTRIBUTE, "[]")
end

local function eggsFolder(): Instance?
    local folder = Workspace:FindFirstChild(EGGS_FOLDER)
    if folder and (folder:IsA("Folder") or folder:IsA("Model")) then
        return folder
    end
    return nil
end

local function variantForKey(key: string): string
    local names: { string } = {}
    local folder = eggsFolder()
    if folder then
        for _, child in folder:GetChildren() do
            if child:IsA("Model") and not SKIP[string.lower(child.Name)] then
                table.insert(names, child.Name)
            end
        end
        table.sort(names)
    end
    if #names == 0 then
        return "Default"
    end
    local h = 0
    for i = 1, #key do
        h = (h * 31 + string.byte(key, i)) % 2147483647
    end
    return names[(h % #names) + 1]
end

local function findFxPart(model: Model): Part?
    local named = model:FindFirstChild(FX_PART_NAME)
    if named and named:IsA("Part") then
        return named
    end
    for _, d in model:GetDescendants() do
        if d:IsA("Part") and d.Name == FX_PART_NAME then
            return d
        end
    end
    return nil
end

-- Templates often have only MeshParts — create Part from AABB for FX / weld root.
local function ensureFxPart(model: Model): Part
    local existing = findFxPart(model)
    if existing then
        existing.Transparency = 1
        existing.CastShadow = false
        return existing
    end
    local ok, cf, size = pcall(function()
        return model:GetBoundingBox()
    end)
    local boxCf = if ok and typeof(cf) == "CFrame" then cf else CFrame.new()
    local boxSize = if ok
            and typeof(size) == "Vector3"
            and size.Magnitude > 0.01
        then size
        else Vector3.new(1.96, 2.48, 1.96)
    local part = Instance.new("Part")
    part.Name = FX_PART_NAME
    part.Size = boxSize
    part.CFrame = boxCf
    part.Transparency = 1
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.CastShadow = false
    part.Parent = model
    return part
end

local function findRightHand(character: Model): BasePart?
    local r15 = character:FindFirstChild("RightHand")
    if r15 and r15:IsA("BasePart") then
        return r15
    end
    local r6 = character:FindFirstChild("Right Arm")
    if r6 and r6:IsA("BasePart") then
        return r6
    end
    return nil
end

local function clearHeldOnCharacter(character: Model)
    local existing = character:FindFirstChild(HELD_NAME)
    if existing then
        existing:Destroy()
    end
end

local function resolveHeld(data: PlayerData?): HeldWant?
    if not data then
        return nil
    end
    local handUid = data.handUid
    if typeof(handUid) ~= "string" or handUid == "" then
        return nil
    end
    local inventory = data.inventory
    if typeof(inventory) ~= "table" then
        return nil
    end
    for _, item in inventory do
        if item and item.uid == handUid then
            local mutations = item.mutations
            return {
                templateId = item.templateId,
                sizeId = if typeof(item.sizeId) == "string" then item.sizeId else "medium",
                mutations = if typeof(mutations) == "table" then mutations else {},
            }
        end
    end
    return nil
end

local function attachHeld(player: Player)
    local character = player.Character
    if not character then
        return
    end
    clearHeldOnCharacter(character)

    local want = _heldWant[player]
    if not want then
        return
    end

    local hand = findRightHand(character)
    if not hand then
        return
    end

    local folder = eggsFolder()
    local variant = variantForKey(want.templateId)
    local template = if folder then folder:FindFirstChild(variant) else nil
    if not (template and template:IsA("Model")) then
        return
    end

    local model = template:Clone()
    model.Name = HELD_NAME
    model.PrimaryPart = nil

    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = false
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false
            d.Massless = true
        end
    end

    local root = ensureFxPart(model)

    local restScale = model:GetScale()
    local scale = ExhibitLogic.visualScale(0, #want.mutations > 0, want.sizeId, want.mutations)
    pcall(function()
        model:ScaleTo(math.max(restScale * scale, 0.08))
    end)

    model:PivotTo(hand.CFrame * GRIP)
    model.Parent = character

    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") and d ~= root then
            local link = Instance.new("WeldConstraint")
            link.Part0 = root
            link.Part1 = d
            link.Parent = root
        end
    end

    local weld = Instance.new("WeldConstraint")
    weld.Name = "HeldEggWeld"
    weld.Part0 = hand
    weld.Part1 = root
    weld.Parent = root
end

function WorldCosmeticPublisher.syncHeldEgg(player: Player, data: PlayerData?)
    if not player.Parent then
        _heldWant[player] = nil
        return
    end
    _heldWant[player] = resolveHeld(data)
    attachHeld(player)
end

function WorldCosmeticPublisher.clearHeldEgg(player: Player)
    _heldWant[player] = nil
    local character = player.Character
    if character then
        clearHeldOnCharacter(character)
    end
end

function WorldCosmeticPublisher.startHeldEgg()
    if _heldStarted then
        return
    end
    _heldStarted = true

    local function onCharacter(player: Player, character: Model)
        task.defer(function()
            if player.Character ~= character then
                return
            end
            local hand = character:FindFirstChild("RightHand")
                or character:WaitForChild("RightHand", 3)
                or character:FindFirstChild("Right Arm")
            if hand then
                attachHeld(player)
            end
        end)
    end

    for _, player in Players:GetPlayers() do
        if player.Character then
            onCharacter(player, player.Character)
        end
        player.CharacterAdded:Connect(function(character)
            onCharacter(player, character)
        end)
    end
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            onCharacter(player, character)
        end)
    end)
    Players.PlayerRemoving:Connect(function(player)
        _heldWant[player] = nil
    end)
end

return WorldCosmeticPublisher
