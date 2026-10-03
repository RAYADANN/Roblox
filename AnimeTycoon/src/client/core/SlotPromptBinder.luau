--!strict
-- Local Place/Open/Skip/Pickup ProximityPrompt visibility for LocalPlayer ramp slots.
-- Slot indices follow shared HeroPlaceLayout (same as server + world renderer).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
local WorldBillboard = require(script.Parent.WorldBillboard)
local Zap = require(script.Parent.Parent.net.NetClient)

export type SlotRow = {
    ownerUserId: number?,
    slotIndex: number,
    unpackProgress: number,
    unpacked: boolean,
    level: number?,
    levelCost: number?,
}

local SlotPromptBinder = {}

local _prompts: {
    [number]: {
        place: ProximityPrompt,
        open: ProximityPrompt,
        skip: ProximityPrompt,
        pickup: ProximityPrompt,
        level: ProximityPrompt,
        part: BasePart,
    },
} =
    {}
local _localSlots: { [number]: SlotRow } = {}
local _wired: { [ProximityPrompt]: boolean } = {}
local _upgrades: { [string]: number } = {}

local function findPrompt(placePart: Instance, name: string): ProximityPrompt?
    local p = placePart:FindFirstChild(name)
    if p and p:IsA("ProximityPrompt") then
        return p
    end
    return nil
end

local function skipRobuxLabel(): string
    local price = ProductIds.SkipUnpackRobuxPrice
    if typeof(price) == "number" and price > 0 then
        return `R${price}`
    end
    return "R$"
end

local function wireOnce(prompt: ProximityPrompt, fn: () -> ())
    if _wired[prompt] then
        return
    end
    _wired[prompt] = true
    prompt.Triggered:Connect(fn)
end

local function ensurePrompt(
    placePart: BasePart,
    name: string,
    action: string,
    object: string,
    kind: string,
    slotIndex: number
): ProximityPrompt
    local prompt = findPrompt(placePart, name)
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = name
        prompt.ActionText = action
        prompt.ObjectText = object
        prompt.RequiresLineOfSight = false
        prompt.Enabled = false
        prompt.MaxActivationDistance = 0
        prompt:SetAttribute("PromptKind", kind)
        prompt.Parent = placePart
    end
    prompt:SetAttribute("SlotIndex", slotIndex)
    return prompt
end

local function cachePrompts()
    table.clear(_prompts)
    local placeParts = HeroPlaceLayout.getOrderedPlaceParts()
    for slotIndex, placePart in placeParts do
        local placePrompt = findPrompt(placePart, "PlacePrompt")
        if not placePrompt then
            continue
        end
        placePart:SetAttribute("SlotIndex", slotIndex)
        placePrompt:SetAttribute("SlotIndex", slotIndex)

        local openPrompt =
            ensurePrompt(placePart, "OpenPrompt", "Open", "Container", "open", slotIndex)
        wireOnce(openPrompt, function()
            Zap.OpenContainer.Call(slotIndex)
        end)

        local skipPrompt = ensurePrompt(
            placePart,
            "SkipPrompt",
            "Open now",
            skipRobuxLabel(),
            "skip_unpack",
            slotIndex
        )
        skipPrompt.ObjectText = skipRobuxLabel()

        local pickupPrompt =
            ensurePrompt(placePart, "PickupPrompt", "Pick up", "Hero", "pickup", slotIndex)
        wireOnce(pickupPrompt, function()
            Zap.PickupContainer.Call(slotIndex)
        end)

        local levelPrompt =
            ensurePrompt(placePart, "LevelPrompt", "Level up", "Hero", "level", slotIndex)
        -- Above PickupPrompt so the two don't stack on the same pad.
        levelPrompt.UIOffset = Vector2.new(0, 100)
        levelPrompt.KeyboardKeyCode = Enum.KeyCode.F
        levelPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
        wireOnce(levelPrompt, function()
            Zap.LevelHero.Call(slotIndex)
        end)

        _prompts[slotIndex] = {
            place = placePrompt,
            open = openPrompt,
            skip = skipPrompt,
            pickup = pickupPrompt,
            level = levelPrompt,
            part = placePart,
        }
    end
end

local function refreshPrompts()
    cachePrompts()
    local unlocked = UpgradeLogic.unlockedSlots(_upgrades)
    for slotIndex = 1, Constants.SLOT_COUNT do
        local pair = _prompts[slotIndex]
        if not pair then
            continue
        end
        local row = _localSlots[slotIndex]
        local occupied = row ~= nil
        local locked = slotIndex > unlocked
        local progress = if occupied then (tonumber(row.unpackProgress) or 0) else 0
        local ready = occupied and row.unpacked ~= true and progress >= 0.999
        local packing = occupied and row.unpacked ~= true and progress < 0.999
        local holding = occupied and row.unpacked == true

        if locked or occupied then
            pair.place.Enabled = false
            pair.place.MaxActivationDistance = 0
        else
            pair.place.Enabled = true
            pair.place.MaxActivationDistance = 12
        end
        pair.open.Enabled = ready and not locked
        pair.open.MaxActivationDistance = if ready and not locked then 12 else 0
        pair.skip.Enabled = packing and not locked
        pair.skip.MaxActivationDistance = if packing and not locked then 12 else 0
        pair.pickup.Enabled = holding and not locked
        pair.pickup.MaxActivationDistance = if holding and not locked then 12 else 0
        local levelCost = if row then (tonumber(row.levelCost) or 0) else 0
        local canLevel = holding and not locked and levelCost > 0
        pair.level.Enabled = canLevel
        pair.level.MaxActivationDistance = if canLevel then 12 else 0
        if canLevel and row then
            local level = tonumber(row.level) or 1
            pair.level.ObjectText = `Lv {level}  {WorldBillboard.shortMoney(levelCost)}`
        end
        if packing then
            pair.skip.ObjectText = skipRobuxLabel()
        end
    end
end

local function ingestSlots(slots: { any }, requireOwner: number?)
    table.clear(_localSlots)
    for _, raw in slots do
        if typeof(raw) ~= "table" then
            continue
        end
        local row = raw :: any
        local slotIndex = tonumber(row.slotIndex)
        if not slotIndex then
            continue
        end
        slotIndex = math.floor(slotIndex)
        if requireOwner ~= nil then
            local owner = tonumber(row.ownerUserId)
            if owner ~= requireOwner then
                continue
            end
        end
        _localSlots[slotIndex] = {
            ownerUserId = tonumber(row.ownerUserId),
            slotIndex = slotIndex,
            unpackProgress = tonumber(row.unpackProgress) or 0,
            unpacked = row.unpacked == true,
            level = tonumber(row.level) or 1,
            levelCost = tonumber(row.levelCost) or 0,
        }
    end
    refreshPrompts()
end

function SlotPromptBinder.applyWorldSlots(slots: { SlotRow })
    local localId = Players.LocalPlayer and Players.LocalPlayer.UserId
    if not localId then
        refreshPrompts()
        return
    end
    ingestSlots(slots :: { any }, localId)
end

function SlotPromptBinder.applyHudSlotsJson(slotsJson: string)
    local decoded = {}
    local ok, result = pcall(function()
        return HttpService:JSONDecode(slotsJson)
    end)
    if ok and typeof(result) == "table" then
        decoded = result
    end
    ingestSlots(decoded, nil)
end

function SlotPromptBinder.applyUpgrades(upgrades: { [string]: number }?)
    _upgrades = upgrades or {}
    refreshPrompts()
end

function SlotPromptBinder.start()
    cachePrompts()
    task.defer(function()
        cachePrompts()
        refreshPrompts()
    end)
    task.delay(1, function()
        cachePrompts()
        refreshPrompts()
    end)
    refreshPrompts()
end

return SlotPromptBinder
