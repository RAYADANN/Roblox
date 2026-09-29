--!strict
-- Render containers / heroes on Ramp.HeroPlace from WorldRampSync.

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local BoxModel = require(script.Parent.BoxModel)
local BoxPresence = require(script.Parent.BoxPresence)
local HeroModel = require(script.Parent.HeroModel)
local SlotPromptBinder = require(script.Parent.SlotPromptBinder)
local WorldBillboard = require(script.Parent.WorldBillboard)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)

export type WorldSlot = {
    ownerUserId: number,
    slotIndex: number,
    uid: string,
    templateId: string,
    boxModelName: string,
    rarity: string,
    heroId: string,
    displayName: string,
    unpackProgress: number,
    unpacked: boolean,
    mutationLabel: string?,
    incomeRate: number?,
}

type VisualState = {
    model: Model,
    uid: string,
    unpacked: boolean,
    boxModelName: string,
    heroId: string,
    billboard: BillboardGui?,
    presence: BoxPresence.Handle?,
}

local RampWorldRenderer = {}

local _folder: Folder? = nil
local _visuals: { [string]: VisualState } = {}
local _placeParts: { BasePart } = {}

local function ensureFolder(): Folder
    if _folder and _folder.Parent then
        return _folder
    end
    local f = Workspace:FindFirstChild("RampWorldVisuals")
    if f and f:IsA("Folder") then
        _folder = f
        return f
    end
    local created = Instance.new("Folder")
    created.Name = "RampWorldVisuals"
    created.Parent = Workspace
    _folder = created
    return created
end

local function cachePlaceParts()
    table.clear(_placeParts)
    for _, pp in HeroPlaceLayout.getOrderedPlaceParts() do
        table.insert(_placeParts, pp)
    end
end

local function slotKey(ownerUserId: number, slotIndex: number): string
    return `{ownerUserId}_{slotIndex}`
end

local function clearVisual(key: string)
    local state = _visuals[key]
    if state then
        if state.presence then
            state.presence.stop()
        end
        state.model:Destroy()
        _visuals[key] = nil
    end
end

local function updateBillboard(state: VisualState, slot: WorldSlot)
    local bb = state.billboard
    if not bb or not bb.Parent then
        local adornee = state.model.PrimaryPart
            or state.model:FindFirstChildWhichIsA("BasePart", true)
        if not adornee or not adornee:IsA("BasePart") then
            return
        end
        bb = WorldBillboard.attach(adornee, "SlotBillboard")
        if bb and slot.unpacked then
            bb.StudsOffset = bb.StudsOffset + Vector3.new(0, 2, 0)
        end
        state.billboard = bb
    end
    if not bb then
        return
    end
    local price: string? = nil
    if slot.unpacked and typeof(slot.incomeRate) == "number" then
        price = WorldBillboard.shortMoney(slot.incomeRate) .. "/trip"
    elseif not slot.unpacked and slot.unpackProgress >= 1 then
        price = "Ready"
    elseif not slot.unpacked then
        price = string.format("%d%%", math.floor(slot.unpackProgress * 100 + 0.5))
    end
    WorldBillboard.set(bb, {
        displayName = slot.displayName,
        rarity = slot.rarity,
        mutationText = slot.mutationLabel,
        priceText = price,
    })
end

local function needsRebuild(state: VisualState?, slot: WorldSlot): boolean
    if not state then
        return true
    end
    if state.uid ~= slot.uid then
        return true
    end
    if state.unpacked ~= slot.unpacked then
        return true
    end
    if not slot.unpacked and state.boxModelName ~= slot.boxModelName then
        return true
    end
    if slot.unpacked and state.heroId ~= slot.heroId then
        return true
    end
    return false
end

local function renderSlot(slot: WorldSlot)
    if #_placeParts == 0 then
        cachePlaceParts()
    end
    local place = _placeParts[slot.slotIndex]
    if not place then
        return
    end
    local key = slotKey(slot.ownerUserId, slot.slotIndex)
    local existing = _visuals[key]

    if not needsRebuild(existing, slot) then
        if existing then
            updateBillboard(existing, slot)
        end
        return
    end

    clearVisual(key)

    local folder = ensureFolder()
    local model: Model?
    if slot.unpacked then
        model = HeroModel.clone(slot.heroId)
        if model then
            HeroModel.placeOn(model, place)
        end
    else
        model = BoxModel.clone(slot.boxModelName)
        if model then
            BoxModel.placeOnHeroStand(model, place)
        end
    end
    if not model then
        return
    end
    model.Parent = folder
    local presence: BoxPresence.Handle? = nil
    if not slot.unpacked then
        presence = BoxPresence.start(model, {
            pad = place,
            allowFocus = false,
            realign = function(m, p)
                BoxModel.placeOnHeroStand(m, p)
            end,
        })
    end
    local state: VisualState = {
        model = model,
        uid = slot.uid,
        unpacked = slot.unpacked,
        boxModelName = slot.boxModelName,
        heroId = slot.heroId,
        billboard = nil,
        presence = presence,
    }
    _visuals[key] = state
    updateBillboard(state, slot)
end

function RampWorldRenderer.applyJson(payloadJson: string)
    local slots: { WorldSlot } = {}
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(payloadJson)
    end)
    if ok and typeof(decoded) == "table" then
        for _, row in decoded :: { any } do
            if typeof(row) == "table" then
                table.insert(slots, row :: WorldSlot)
            end
        end
    end

    local live: { [string]: boolean } = {}
    for _, slot in slots do
        local key = slotKey(slot.ownerUserId, slot.slotIndex)
        live[key] = true
        renderSlot(slot)
    end
    for key in _visuals do
        if not live[key] then
            clearVisual(key)
        end
    end
    SlotPromptBinder.applyWorldSlots(slots)
end

function RampWorldRenderer.getPlacePart(slotIndex: number): BasePart?
    if #_placeParts == 0 then
        cachePlaceParts()
    end
    return _placeParts[slotIndex]
end

function RampWorldRenderer.start()
    cachePlaceParts()
    ensureFolder()
    SlotPromptBinder.start()
end

return RampWorldRenderer
