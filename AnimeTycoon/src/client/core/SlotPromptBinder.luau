--!strict
-- Local Place/Open ProximityPrompt visibility for LocalPlayer ramp slots.
-- Slot indices follow shared HeroPlaceLayout (same as server + world renderer).
-- Server also syncs Enabled; this keeps Open gated to the local owner's Ready state.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)
local Zap = require(script.Parent.Parent.net.NetClient)

export type SlotRow = {
    ownerUserId: number?,
    slotIndex: number,
    unpackProgress: number,
    unpacked: boolean,
}

local SlotPromptBinder = {}

local _prompts: { [number]: { place: ProximityPrompt, open: ProximityPrompt, part: BasePart } } = {}
local _localSlots: { [number]: SlotRow } = {}
local _openWired: { [ProximityPrompt]: boolean } = {}

local function findPrompt(placePart: Instance, name: string): ProximityPrompt?
    local p = placePart:FindFirstChild(name)
    if p and p:IsA("ProximityPrompt") then
        return p
    end
    return nil
end

local function wireOpen(openPrompt: ProximityPrompt, slotIndex: number)
    if _openWired[openPrompt] then
        return
    end
    _openWired[openPrompt] = true
    openPrompt.Triggered:Connect(function()
        Zap.OpenContainer.Call(slotIndex)
    end)
end

local function cachePrompts()
    table.clear(_prompts)
    local placeParts = HeroPlaceLayout.getOrderedPlaceParts()
    for slotIndex, placePart in placeParts do
        local placePrompt = findPrompt(placePart, "PlacePrompt")
        local openPrompt = findPrompt(placePart, "OpenPrompt")
        if not placePrompt then
            continue
        end
        placePart:SetAttribute("SlotIndex", slotIndex)
        placePrompt:SetAttribute("SlotIndex", slotIndex)
        if not openPrompt then
            openPrompt = Instance.new("ProximityPrompt")
            openPrompt.Name = "OpenPrompt"
            openPrompt.ActionText = "Open"
            openPrompt.ObjectText = "Container"
            openPrompt.RequiresLineOfSight = false
            openPrompt.Enabled = false
            openPrompt:SetAttribute("PromptKind", "open")
            openPrompt.Parent = placePart
        end
        openPrompt:SetAttribute("SlotIndex", slotIndex)
        wireOpen(openPrompt, slotIndex)
        _prompts[slotIndex] = { place = placePrompt, open = openPrompt, part = placePart }
    end
end

local function refreshPrompts()
    -- Always re-resolve refs: server remakes prompts on boot.
    cachePrompts()
    for slotIndex = 1, Constants.SLOT_COUNT do
        local pair = _prompts[slotIndex]
        if not pair then
            continue
        end
        local row = _localSlots[slotIndex]
        local occupied = row ~= nil
        local ready = occupied
            and row.unpacked ~= true
            and (tonumber(row.unpackProgress) or 0) >= 0.999

        -- Prefer hiding Place when occupied; Open only for local Ready.
        -- Server also sets these — local tweak wins for this client's UX.
        if occupied then
            pair.place.Enabled = false
            pair.place.MaxActivationDistance = 0
        end
        pair.open.Enabled = ready
        pair.open.MaxActivationDistance = if ready then 12 else 0
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
