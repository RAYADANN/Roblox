--!strict
-- Render containers / heroes on Ramp.HeroPlace from WorldRampSync.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BoxModel = require(script.Parent.BoxModel)
local BoxPresence = require(script.Parent.BoxPresence)
local HeroModel = require(script.Parent.HeroModel)
local SlotPromptBinder = require(script.Parent.SlotPromptBinder)
local WorldBillboard = require(script.Parent.WorldBillboard)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
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
    unpackEndsAt: number?,
    mutations: { string }?,
    mutationLabel: string?,
    incomeRate: number?,
    level: number?,
}

type VisualState = {
    model: Model,
    uid: string,
    unpacked: boolean,
    boxModelName: string,
    heroId: string,
    templateId: string,
    unpackEndsAt: number?,
    lastTimerText: string?,
    billboard: BillboardGui?,
    presence: BoxPresence.Handle?,
    slotSnapshot: WorldSlot,
}

local RampWorldRenderer = {}

local _folder: Folder? = nil
local _visuals: { [string]: VisualState } = {}
local _placeParts: { BasePart } = {}
local _placePartsByOwner: { [number]: { BasePart } } = {}
local _timerConn: RBXScriptConnection? = nil
local _timerAccum = 0
local _attrConns: { RBXScriptConnection } = {}

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
    table.clear(_placePartsByOwner)
    for _, base in BaseLayout.getAll() do
        local parts = HeroPlaceLayout.getOrderedPlaceParts(base)
        local ownerId = BaseLayout.getOwnerUserId(base)
        if ownerId then
            _placePartsByOwner[ownerId] = parts
        end
    end
    local localBase = BaseLayout.getLocal() or BaseLayout.getPrimary()
    if localBase then
        for _, pp in HeroPlaceLayout.getOrderedPlaceParts(localBase) do
            table.insert(_placeParts, pp)
        end
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

local function packingPriceText(slot: WorldSlot, now: number): string
    local endsAt = tonumber(slot.unpackEndsAt)
    if endsAt and endsAt > 0 then
        local rem = math.max(0, endsAt - now)
        if rem <= 0 or (tonumber(slot.unpackProgress) or 0) >= 0.999 then
            return "Ready"
        end
        return ContainerLogic.formatRemaining(rem)
    end
    if (tonumber(slot.unpackProgress) or 0) >= 0.999 then
        return "Ready"
    end
    return "…"
end

local function updateBillboard(state: VisualState, slot: WorldSlot, now: number?)
    local bb = state.billboard
    if not bb or not bb.Parent then
        local adornee = state.model.PrimaryPart
            or state.model:FindFirstChildWhichIsA("BasePart", true)
        if not adornee or not adornee:IsA("BasePart") then
            return
        end
        bb = WorldBillboard.attach(adornee, "SlotBillboard")
        if bb and slot.unpacked then
            -- World-space only — do not stack with template StudsOffset (0, 8, 0).
            bb.StudsOffset = Vector3.zero
            bb.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
        end
        state.billboard = bb
    end
    if not bb then
        return
    end
    if slot.unpacked then
        bb.StudsOffset = Vector3.zero
        bb.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
    end
    local clock = now or os.time()
    local price: string? = nil
    if slot.unpacked and typeof(slot.incomeRate) == "number" then
        local level = if typeof(slot.level) == "number" then math.floor(slot.level) else 1
        price = `Lv {level} · {WorldBillboard.shortMoney(slot.incomeRate)}/trip`
    elseif not slot.unpacked then
        price = packingPriceText(slot, clock)
        if price == state.lastTimerText then
            return
        end
    end
    state.lastTimerText = price
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
    if slot.unpacked and (state.templateId or "") ~= (slot.templateId or "") then
        return true
    end
    -- Limited sync may rewrite Null rarity / mutations → force remesh to stand model.
    if slot.unpacked and state.slotSnapshot.rarity ~= slot.rarity then
        return true
    end
    return false
end

local function renderSlot(slot: WorldSlot)
    cachePlaceParts()
    local ownerParts = _placePartsByOwner[slot.ownerUserId]
    local place = if ownerParts then ownerParts[slot.slotIndex] else nil
    if not place then
        -- Owner not claimed yet / base missing — skip until ownership syncs.
        return
    end
    local key = slotKey(slot.ownerUserId, slot.slotIndex)
    local existing = _visuals[key]

    if not needsRebuild(existing, slot) then
        if existing then
            existing.unpackEndsAt = slot.unpackEndsAt
            existing.slotSnapshot = slot
            updateBillboard(existing, slot)
        end
        return
    end

    clearVisual(key)

    local folder = ensureFolder()
    local model: Model?
    if slot.unpacked then
        -- Defer FX until placeOn: feet/origin first, then visual-center FX (preview path).
        model = HeroModel.clone(slot.heroId, nil, {
            rarity = slot.rarity,
            mutations = slot.mutations,
            mutationLabel = slot.mutationLabel,
            templateId = slot.templateId,
            deferMutationFx = true,
        })
        if model then
            model.Parent = folder
            HeroModel.placeOn(model, place)
        end
    else
        model = BoxModel.clone(slot.boxModelName, {
            mutations = slot.mutations,
            mutationLabel = slot.mutationLabel,
        })
        if model then
            BoxModel.placeOnHeroStand(model, place)
        end
    end
    if not model then
        return
    end
    if model.Parent ~= folder then
        model.Parent = folder
    end
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
        templateId = slot.templateId or "",
        unpackEndsAt = slot.unpackEndsAt,
        lastTimerText = nil,
        billboard = nil,
        presence = presence,
        slotSnapshot = slot,
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

function RampWorldRenderer.getPlacePartForOwner(ownerUserId: number, slotIndex: number): BasePart?
    cachePlaceParts()
    local parts = _placePartsByOwner[ownerUserId]
    if parts then
        return parts[slotIndex]
    end
    return nil
end

--- Best MeshPart / Part on the local player's slot visual (box or hero).
function RampWorldRenderer.getLocalSlotAttachPart(slotIndex: number): BasePart?
    local player = Players.LocalPlayer
    if player == nil then
        return RampWorldRenderer.getPlacePart(slotIndex)
    end
    local key = slotKey(player.UserId, slotIndex)
    local state = _visuals[key]
    if state and state.model and state.model.Parent then
        local best: BasePart? = nil
        local bestScore = -1
        for _, d in state.model:GetDescendants() do
            if d:IsA("BasePart") then
                local vol = d.Size.X * d.Size.Y * d.Size.Z
                local score = if d:IsA("MeshPart") then vol * 10 else vol
                if score > bestScore then
                    bestScore = score
                    best = d
                end
            end
        end
        if best then
            return best
        end
        local primary = state.model.PrimaryPart
        if primary then
            return primary
        end
    end
    return RampWorldRenderer.getPlacePart(slotIndex)
end

local function tickTimers(dt: number)
    _timerAccum += dt
    if _timerAccum < 0.2 then
        return
    end
    _timerAccum = 0
    local now = os.time()
    for _, state in _visuals do
        if state.unpacked then
            continue
        end
        local slot = state.slotSnapshot
        local nextText = packingPriceText(slot, now)
        if nextText ~= state.lastTimerText then
            updateBillboard(state, slot, now)
        end
    end
end

local function bindOwnershipWatch()
    for _, c in _attrConns do
        c:Disconnect()
    end
    table.clear(_attrConns)
    for _, base in BaseLayout.getAll() do
        table.insert(
            _attrConns,
            base:GetAttributeChangedSignal(BaseLayout.ATTR_OWNER_USER_ID):Connect(function()
                cachePlaceParts()
                SlotPromptBinder.start()
            end)
        )
    end
    local player = Players.LocalPlayer
    if player then
        table.insert(
            _attrConns,
            player:GetAttributeChangedSignal(BaseLayout.PLAYER_ATTR_BASE_NAME):Connect(function()
                cachePlaceParts()
                SlotPromptBinder.start()
            end)
        )
    end
end

function RampWorldRenderer.start()
    cachePlaceParts()
    ensureFolder()
    bindOwnershipWatch()
    SlotPromptBinder.start()
    if _timerConn then
        _timerConn:Disconnect()
        _timerConn = nil
    end
    _timerConn = RunService.Heartbeat:Connect(tickTimers)
end

return RampWorldRenderer
