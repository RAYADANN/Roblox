--!strict
-- Spawns farm heroes from Workspace.Characters (one model per merge tier).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local DropDatabase = require(ReplicatedStorage.shared.data.DropDatabase)
local FarmLogic = require(ReplicatedStorage.shared.util.FarmLogic)
local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local HeroLogic = require(ReplicatedStorage.shared.util.HeroLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local PadIds = require(ReplicatedStorage.shared.data.PadIds)
local SlotLayoutLogic = require(ReplicatedStorage.shared.util.SlotLayoutLogic)
local WorldHeroCatalog = require(script.Parent.WorldHeroCatalog)

export type DropKind = DropDatabase.DropKind

local TEMPLATE_NAME = "FarmDummyTemplate"
local DUMMY_ITEMS_FOLDER = "DummyItems"

local WorldFarmFactory = {}

local function firstBasePart(root: Instance): BasePart?
    for _, inst in root:GetDescendants() do
        if inst:IsA("BasePart") then
            return inst
        end
    end
    return nil
end

local function setAnchored(model: Model)
    for _, inst in model:GetDescendants() do
        if inst:IsA("BasePart") then
            inst.Anchored = true
            inst.CanCollide = false
            inst.Massless = true
        elseif inst:IsA("Highlight") then
            inst.Enabled = false
        end
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

local function hideModel(model: Model)
    for _, inst in model:GetDescendants() do
        if inst:IsA("BasePart") then
            inst.Transparency = 1
            inst.CanCollide = false
            inst.CanQuery = false
            inst.CanTouch = false
            inst.Anchored = true
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            inst.Transparency = 1
        elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            inst.Enabled = false
        elseif inst:IsA("Humanoid") then
            inst.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            inst.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            inst.PlatformStand = true
        end
    end
end

local function dummyItemsFolder(island: Folder): Folder?
    local folder = island:FindFirstChild(DUMMY_ITEMS_FOLDER)
    if folder and folder:IsA("Folder") then
        return folder
    end
    return nil
end

type RankedMarker = {
    floor: number,
    model: Model,
}

function WorldFarmFactory.slotMarkers(island: Folder): { Model }
    local folder = dummyItemsFolder(island)
    local ranked: { RankedMarker } = {}
    if folder == nil then
        return {}
    end

    local fromFloorFolders = false
    for _, child in folder:GetChildren() do
        if child:IsA("Folder") then
            local floorIndex = SlotLayoutLogic.floorIndexFromName(child.Name)
            if floorIndex ~= nil then
                fromFloorFolders = true
                for _, marker in child:GetChildren() do
                    if marker:IsA("Model") then
                        table.insert(ranked, { floor = floorIndex, model = marker })
                    end
                end
            end
        end
    end

    if not fromFloorFolders then
        for _, child in folder:GetChildren() do
            if child:IsA("Model") then
                table.insert(ranked, { floor = 1, model = child })
            end
        end
    end

    table.sort(ranked, function(a, b)
        local pa = a.model:GetPivot().Position
        local pb = b.model:GetPivot().Position
        return SlotLayoutLogic.compareKeys({
            floor = a.floor,
            x = pa.X,
            z = pa.Z,
            name = a.model.Name,
        }, {
            floor = b.floor,
            x = pb.X,
            z = pb.Z,
            name = b.model.Name,
        })
    end)

    local markers: { Model } = table.create(#ranked)
    for i, entry in ranked do
        markers[i] = entry.model
    end

    local expected = SlotLayoutLogic.expectedSlotCount()
    if #markers > 0 and #markers ~= expected then
        Logger.warn(
            "WorldFarmFactory",
            `{island.Name} DummyItems has {#markers} slots (expected {expected} = {Constants.SLOT_FLOORS}×{Constants.SLOTS_PER_FLOOR})`
        )
    end

    return markers
end

local function modelHasBasePart(model: Model): boolean
    for _, inst in model:GetDescendants() do
        if inst:IsA("BasePart") then
            return true
        end
    end
    return false
end

local function modelHasBillboard(model: Model): boolean
    for _, inst in model:GetDescendants() do
        if inst:IsA("BillboardGui") then
            return true
        end
    end
    return false
end

-- IslandMain DummyItems are pivot-only; some R15 Dummy copies lost BillboardGui.
-- Prefer a donor that still has the level/name billboard so spawned units stay labeled.
local function findBillboardDonor(): BillboardGui?
    for _, child in Workspace:GetChildren() do
        if child.Name == "Island" or child.Name == "IslandMain" then
            for _, dummy in child:GetChildren() do
                if dummy.Name == "R15 Dummy" and dummy:IsA("Model") then
                    for _, inst in dummy:GetDescendants() do
                        if inst:IsA("BillboardGui") then
                            return inst
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function ensureUnitBillboardTree(model: Model)
    if modelHasBillboard(model) then
        return
    end
    local donor = findBillboardDonor()
    if donor == nil then
        Logger.warn("WorldFarmFactory", `{model.Name} missing BillboardGui and no donor found`)
        return
    end
    local clone = donor:Clone()
    clone.Enabled = true
    clone.Parent = model
end

local function findTemplateSource(island: Folder, markers: { Model }): Model?
    local fallback: Model? = nil
    for _, marker in markers do
        if modelHasBasePart(marker) then
            if modelHasBillboard(marker) then
                return marker
            end
            if fallback == nil then
                fallback = marker
            end
        end
    end

    local legacy = island:FindFirstChild("R15 Dummy")
    if legacy and legacy:IsA("Model") and modelHasBasePart(legacy) then
        if modelHasBillboard(legacy) then
            return legacy
        end
        if fallback == nil then
            fallback = legacy
        end
    end

    return fallback
end

local function makeStubTemplate(): Model
    local stub = Instance.new("Model")
    stub.Name = TEMPLATE_NAME
    local part = Instance.new("Part")
    part.Name = "HumanoidRootPart"
    part.Size = Vector3.new(2, 5, 1)
    part.Anchored = true
    part.Parent = stub
    stub.PrimaryPart = part
    stub.Parent = ServerStorage
    ensureUnitBillboardTree(stub)
    return stub
end

function WorldFarmFactory.ensureTemplate(island: Folder): Model
    local existing = ServerStorage:FindFirstChild(TEMPLATE_NAME)
    if existing and existing:IsA("Model") then
        if modelHasBasePart(existing) then
            ensureUnitBillboardTree(existing)
            return existing
        end
        existing:Destroy()
    end

    local markers = WorldFarmFactory.slotMarkers(island)
    local source = findTemplateSource(island, markers)
    if source == nil then
        Logger.warn("WorldFarmFactory", `{island.Name} has no dummy geometry; stub template`)
        return makeStubTemplate()
    end

    local clone = source:Clone()
    clone.Name = TEMPLATE_NAME
    setAnchored(clone)
    ensureUnitBillboardTree(clone)
    clone.Parent = ServerStorage
    return clone
end

function WorldFarmFactory.hideSlotMarkers(island: Folder)
    for _, marker in WorldFarmFactory.slotMarkers(island) do
        hideModel(marker)
    end
    for _, child in island:GetChildren() do
        if child.Name == "R15 Dummy" and child:IsA("Model") then
            hideModel(child)
        end
    end
end

function WorldFarmFactory.buildSlots(island: Folder): { CFrame }
    local slots: { CFrame } = {}
    for _, marker in WorldFarmFactory.slotMarkers(island) do
        table.insert(slots, marker:GetPivot())
    end
    return slots
end

function WorldFarmFactory.publishHeroCatalog()
    WorldHeroCatalog.publish()
end

function WorldFarmFactory.preparePlot(island: Folder): (Model, { CFrame })
    WorldHeroCatalog.publish()
    local template = WorldFarmFactory.ensureTemplate(island)
    local slots = WorldFarmFactory.buildSlots(island)
    WorldFarmFactory.hideSlotMarkers(island)
    WorldFarmFactory.setupDropConveyor(island)
    if #slots == 0 then
        Logger.warn("WorldFarmFactory", `{island.Name} DummyItems is empty`)
    end
    return template, slots
end

-- Chicken Farm pattern: anchored Stand floor gets AssemblyLinearVelocity once;
-- unanchored drops are pushed by physics toward the tip (no per-drop movers).
function WorldFarmFactory.setupDropConveyor(island: Folder)
    local stand = island:FindFirstChild("Stand")
    if stand == nil or not stand:IsA("Model") then
        Logger.warn("WorldFarmFactory", `{island.Name} missing Stand conveyor`)
        return
    end

    local tipPart = stand:FindFirstChild("Plane")
    local look = stand:GetPivot().LookVector
    if tipPart and tipPart:IsA("BasePart") then
        local origin = stand:GetPivot().Position
        local toTip = Vector3.new(tipPart.Position.X - origin.X, 0, tipPart.Position.Z - origin.Z)
        if toTip.Magnitude > 1e-3 then
            look = toTip.Unit
        end
    end

    local velocity = FarmLogic.conveyorVelocity(look.X, look.Z, Constants.DROP_CONVEYOR_SPEED)
    local worldVel = Vector3.new(velocity.x, velocity.y, velocity.z)
    -- Only the trough floor (Cube) slides drops. Plane is the tip zone — no conveyor.
    local floor = stand:FindFirstChild("Cube")
    if floor and floor:IsA("BasePart") then
        floor.Anchored = true
        floor.AssemblyLinearVelocity = worldVel
    end
    local tip = stand:FindFirstChild("Plane")
    if tip and tip:IsA("BasePart") then
        tip.Anchored = true
        tip.AssemblyLinearVelocity = Vector3.zero
    end
end

-- Stand tip (Plane): Auto Collect zone after cubes slide down the trough.
function WorldFarmFactory.findCollectTip(island: Folder): BasePart?
    local stand = island:FindFirstChild("Stand")
    if stand == nil or not stand:IsA("Model") then
        return nil
    end
    local tip = stand:FindFirstChild("Plane")
    if tip and tip:IsA("BasePart") then
        return tip
    end
    return nil
end

function WorldFarmFactory.ensureFolder(island: Folder, name: string): Folder
    local existing = island:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        existing:ClearAllChildren()
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = island
    return folder
end

local function setUnitBillboard(unit: Model, tier: number, displayName: string)
    ensureUnitBillboardTree(unit)
    local adornee = WorldHeroCatalog.ensureStandPart(unit)
    local head = unit:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        adornee = head
    end
    for _, inst in unit:GetDescendants() do
        if inst:IsA("TextLabel") then
            if inst.Name == "Price" then
                inst.Text = `Level {tier}`
            elseif inst.Name == "TagName" then
                inst.Text = displayName
            end
        elseif inst:IsA("BillboardGui") then
            inst.Enabled = true
            if adornee then
                inst.Adornee = adornee
            end
            inst.StudsOffset = inst.StudsOffset + Vector3.new(0, inst.Size.Y.Scale, 0)
        end
    end
end

function WorldFarmFactory.spawnUnit(
    parent: Instance,
    template: Model,
    cf: CFrame,
    tier: number
): Model
    local hero = WorldHeroCatalog.templateForTier(tier)
    local source = if hero then hero else template
    local unit = source:Clone()
    unit.Name = `Unit_{tier}`
    unit:SetAttribute("Tier", tier)
    WorldHeroCatalog.ensureStandPart(unit)
    for _, inst in unit:GetDescendants() do
        if inst:IsA("Script") or inst:IsA("LocalScript") then
            inst.Disabled = true
        end
    end
    setAnchored(unit)
    setUnitBillboard(unit, tier, HeroLogic.displayName(HeroLogic.modelNameForTier(tier)))
    unit:PivotTo(cf)
    unit.Parent = parent
    return unit
end

function WorldFarmFactory.spawnDrop(
    parent: Instance,
    cf: CFrame,
    kind: DropKind,
    value: number,
    ownerUserId: number
): BasePart
    local part = Instance.new("Part")
    part.Name = "DropCube"
    part.Size = Vector3.new(1.2, 1.2, 1.2)
    part.Shape = Enum.PartType.Block
    part.Anchored = false
    part.CanCollide = true
    part.CanQuery = true
    part.CanTouch = true
    part.Massless = false
    part.Material = Enum.Material.SmoothPlastic
    part.Color = Color3.fromRGB(DropDatabase[kind].r, DropDatabase[kind].g, DropDatabase[kind].b)
    part.CustomPhysicalProperties = PhysicalProperties.new(
        Constants.DROP_DENSITY,
        Constants.DROP_FRICTION,
        Constants.DROP_ELASTICITY,
        1,
        1
    )
    part.CFrame = cf
    part:SetAttribute("DropKind", kind)
    part:SetAttribute("EggValue", value)
    part:SetAttribute("OwnerUserId", ownerUserId)
    part.Parent = parent
    pcall(function()
        part:SetNetworkOwner(nil)
    end)
    return part
end

function WorldFarmFactory.findPadPart(model: Instance): BasePart?
    -- Prefer stable rim (not animated Cube.001 / Cube.002).
    local rim = model:FindFirstChild("Cube")
    if rim and rim:IsA("BasePart") then
        return rim
    end
    local face = model:FindFirstChild("Cube.001")
    if face and face:IsA("BasePart") then
        return face
    end
    return firstBasePart(model)
end

function WorldFarmFactory.setPadText(model: Instance?, title: string?, price: string?)
    if model == nil then
        return
    end
    for _, inst in model:GetDescendants() do
        if inst:IsA("TextLabel") then
            if inst.Name == "TagName" and title ~= nil then
                inst.Text = title
            elseif inst.Name == "Price" and price ~= nil then
                inst.Text = price
            end
        end
    end
end

function WorldFarmFactory.setCountBoard(island: Folder, queueCash: number, perSec: number)
    local board = island:FindFirstChild("CountBilboard")
    if board == nil then
        return
    end
    for _, inst in board:GetDescendants() do
        if inst:IsA("TextLabel") then
            if inst.Name == "Title" then
                inst.Text = "Selling Items"
            elseif inst.Name == "Count" then
                inst.Text = `${FormatMoney.short(queueCash)}`
            elseif inst.Name == "CountPerSecond" then
                inst.Text = `${FormatMoney.rate(perSec)} per second`
            end
        end
    end
end

function WorldFarmFactory.padModels(island: Folder): { [string]: Instance }
    local found: { [string]: Instance } = {}
    for _, def in PadIds do
        local parent: Instance? = if def.parent == "Buttons"
            then island:FindFirstChild("Buttons")
            else island
        if parent then
            local model = parent:FindFirstChild(def.modelName)
            if model then
                found[def.action] = model
            end
        end
    end
    return found
end

return WorldFarmFactory
