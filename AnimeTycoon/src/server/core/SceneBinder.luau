--!strict
-- Bind ProximityPrompts on every Base plot. Trigger only for that base's owner.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)
local LimitedOfferDatabase = require(ReplicatedStorage.shared.data.LimitedOfferDatabase)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)

export type Deps = {
    onRoll: (player: Player) -> (),
    onBuy: (player: Player, offerIndex: number) -> (),
    onPlace: (player: Player, slotIndex: number) -> (),
    onOpen: (player: Player, slotIndex: number) -> (),
    onSkipUnpack: (player: Player, slotIndex: number) -> (),
    onPickup: (player: Player, slotIndex: number) -> (),
    onTakeSellBox: (player: Player) -> (),
    onSellCrates: (player: Player) -> (),
    onBuyLimited: (player: Player, standId: string) -> (),
    --- Optional: reject if player does not own the prompt's base.
    ownsInstance: ((player: Player, inst: Instance?) -> boolean)?,
}

export type SlotPromptState = {
    occupied: boolean,
    ready: boolean,
    packing: boolean?,
    holding: boolean?,
}

local SceneBinder = {}

local _slotPrompts: {
    [Instance]: {
        [number]: {
            place: ProximityPrompt,
            open: ProximityPrompt,
            skip: ProximityPrompt,
            pickup: ProximityPrompt,
        },
    },
} =
    {}
local _ownsInstance: ((player: Player, inst: Instance?) -> boolean)? = nil

local function remakePrompt(parent: Instance, name: string): ProximityPrompt
    local existing = parent:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = name
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 12
    prompt.Parent = parent
    return prompt
end

local function promptHost(model: Instance?): BasePart?
    if not model then
        return nil
    end
    if model:IsA("Model") then
        local primary = model.PrimaryPart
        if primary then
            return primary
        end
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function skipRobuxLabel(): string
    local price = ProductIds.SkipUnpackRobuxPrice
    if typeof(price) == "number" and price > 0 then
        return `R${price}`
    end
    return "R$"
end

local function limitedRobuxLabel(standId: string): string
    local offer = LimitedOfferDatabase.get(standId)
    if offer and offer.robuxPrice > 0 then
        return `R${offer.robuxPrice}`
    end
    return "R$"
end

local function updateLimitedCountLabel(stand: Instance, remaining: number, stockMax: number)
    local bb = stand:FindFirstChild("BillboardGui")
    if not bb then
        return
    end
    local frame = bb:FindFirstChild("Frame")
    if not frame then
        return
    end
    local count = frame:FindFirstChild("Count")
    if count and count:IsA("TextLabel") then
        count.Text = `{remaining}/{stockMax}`
    end
end

local function limitedPromptHost(stand: Instance): BasePart?
    local price = stand:FindFirstChild("Price")
    if price and price:IsA("BasePart") then
        return price
    end
    return promptHost(stand)
end

local function gate(player: Player, host: Instance?): boolean
    local fn = _ownsInstance
    if fn == nil then
        return true
    end
    return fn(player, host)
end

local function installBase(base: Instance, deps: Deps)
    local stands = BaseLayout.getStands(base)
    if stands then
        local roll = stands:FindFirstChild("RollButton")
        if roll then
            local btn = roll:FindFirstChild("Button")
                or roll:FindFirstChildWhichIsA("BasePart", true)
            if btn then
                local prompt = remakePrompt(btn, "RollPrompt")
                prompt.ActionText = "Roll"
                prompt.ObjectText = "Stands"
                prompt:SetAttribute("PromptKind", "roll")
                prompt.Triggered:Connect(function(player)
                    if not gate(player, btn) then
                        return
                    end
                    deps.onRoll(player)
                end)
            end
        end

        for i = 1, Constants.OFFER_COUNT do
            local stand = stands:FindFirstChild("Stand" .. i)
            if stand then
                local pad = stand:FindFirstChild("BoxPlace") or stand:FindFirstChild("EggPlace")
                if pad and pad:IsA("BasePart") then
                    local prompt = remakePrompt(pad, "BuyPrompt")
                    prompt.ActionText = "Buy"
                    prompt.ObjectText = "Container"
                    prompt.Enabled = false
                    prompt:SetAttribute("PromptKind", "buy")
                    prompt:SetAttribute("OfferIndex", i)
                    prompt.Triggered:Connect(function(player)
                        if not gate(player, pad) then
                            return
                        end
                        deps.onBuy(player, i)
                    end)
                end
            end
        end
    end

    local baseSlots: {
        [number]: {
            place: ProximityPrompt,
            open: ProximityPrompt,
            skip: ProximityPrompt,
            pickup: ProximityPrompt,
        },
    } =
        {}
    local placeParts = HeroPlaceLayout.getOrderedPlaceParts(base)
    for slotIndex, placePart in placeParts do
        placePart:SetAttribute("SlotIndex", slotIndex)

        local placePrompt = remakePrompt(placePart, "PlacePrompt")
        placePrompt.ActionText = "Place"
        placePrompt.ObjectText = "Hero Place"
        placePrompt:SetAttribute("PromptKind", "place")
        placePrompt:SetAttribute("SlotIndex", slotIndex)
        placePrompt.Triggered:Connect(function(player)
            if not gate(player, placePart) then
                return
            end
            deps.onPlace(player, slotIndex)
        end)

        local openPrompt = remakePrompt(placePart, "OpenPrompt")
        openPrompt.ActionText = "Open"
        openPrompt.ObjectText = "Container"
        openPrompt.Enabled = false
        openPrompt:SetAttribute("PromptKind", "open")
        openPrompt:SetAttribute("SlotIndex", slotIndex)
        openPrompt.Triggered:Connect(function(player)
            if not gate(player, placePart) then
                return
            end
            deps.onOpen(player, slotIndex)
        end)

        local skipPrompt = remakePrompt(placePart, "SkipPrompt")
        skipPrompt.ActionText = "Open now"
        skipPrompt.ObjectText = skipRobuxLabel()
        skipPrompt.Enabled = false
        skipPrompt.MaxActivationDistance = 0
        skipPrompt:SetAttribute("PromptKind", "skip_unpack")
        skipPrompt:SetAttribute("SlotIndex", slotIndex)
        skipPrompt.Triggered:Connect(function(player)
            if not gate(player, placePart) then
                return
            end
            deps.onSkipUnpack(player, slotIndex)
        end)

        local pickupPrompt = remakePrompt(placePart, "PickupPrompt")
        pickupPrompt.ActionText = "Pick up"
        pickupPrompt.ObjectText = "Hero"
        pickupPrompt.Enabled = false
        pickupPrompt.MaxActivationDistance = 0
        pickupPrompt:SetAttribute("PromptKind", "pickup")
        pickupPrompt:SetAttribute("SlotIndex", slotIndex)
        pickupPrompt.Triggered:Connect(function(player)
            if not gate(player, placePart) then
                return
            end
            deps.onPickup(player, slotIndex)
        end)

        baseSlots[slotIndex] = {
            place = placePrompt,
            open = openPrompt,
            skip = skipPrompt,
            pickup = pickupPrompt,
        }
    end
    _slotPrompts[base] = baseSlots

    local sellBoxHost = promptHost(BaseLayout.getSellBox(base))
    if sellBoxHost then
        local take = remakePrompt(sellBoxHost, "TakeSellBoxPrompt")
        take.ActionText = "Take"
        take.ObjectText = "Sell Box"
        take:SetAttribute("PromptKind", "take_sellbox")
        take.Enabled = true
        take.Triggered:Connect(function(player)
            if not gate(player, sellBoxHost) then
                return
            end
            deps.onTakeSellBox(player)
        end)
    else
        warn(`[SceneBinder] SellBox host missing on {base.Name}`)
    end

    local sellGuyHost = promptHost(BaseLayout.getSellGuy(base))
    if sellGuyHost then
        local sell = remakePrompt(sellGuyHost, "SellCratesPrompt")
        sell.ActionText = "Sell"
        sell.ObjectText = "Sell Guy"
        sell:SetAttribute("PromptKind", "sell_crates")
        sell.Enabled = true
        sell.Triggered:Connect(function(player)
            if not gate(player, sellGuyHost) then
                return
            end
            deps.onSellCrates(player)
        end)
    else
        warn(`[SceneBinder] SellGuy host missing on {base.Name}`)
    end

    local limited = BaseLayout.getLimited(base)
    if limited then
        for _, offer in LimitedOfferDatabase.all() do
            local stand = limited:FindFirstChild(offer.standId)
            if not stand then
                warn(`[SceneBinder] Limited stand missing: {base.Name}/{offer.standId}`)
                continue
            end
            local host = limitedPromptHost(stand)
            if not host then
                warn(`[SceneBinder] Limited prompt host missing: {base.Name}/{offer.standId}`)
                continue
            end
            local prompt = remakePrompt(host, "LimitedBuyPrompt")
            prompt.ActionText = "Buy"
            prompt.ObjectText = limitedRobuxLabel(offer.standId)
            prompt.MaxActivationDistance = 14
            prompt:SetAttribute("PromptKind", "buy_limited")
            prompt:SetAttribute("StandId", offer.standId)
            prompt.Triggered:Connect(function(player)
                if not gate(player, host) then
                    return
                end
                deps.onBuyLimited(player, offer.standId)
            end)
            updateLimitedCountLabel(stand, offer.stockMax, offer.stockMax)
        end
    end
end

function SceneBinder.install(deps: Deps)
    table.clear(_slotPrompts)
    _ownsInstance = deps.ownsInstance

    local bases = BaseLayout.getAll()
    if #bases == 0 then
        warn("[SceneBinder] no bases found in Workspace")
        return
    end
    for _, base in bases do
        installBase(base, deps)
    end
end

function SceneBinder.setLimitedStock(standId: string, remaining: number, stockMax: number)
    for _, base in BaseLayout.getAll() do
        local limited = BaseLayout.getLimited(base)
        if not limited then
            continue
        end
        local stand = limited:FindFirstChild(standId)
        if not stand then
            continue
        end
        updateLimitedCountLabel(stand, remaining, stockMax)
        local host = limitedPromptHost(stand)
        if host then
            local prompt = host:FindFirstChild("LimitedBuyPrompt")
            if prompt and prompt:IsA("ProximityPrompt") then
                prompt.Enabled = remaining > 0
                prompt.MaxActivationDistance = if remaining > 0 then 14 else 0
                prompt.ObjectText = limitedRobuxLabel(standId)
            end
        end
    end
end

--- Per-owner slot prompt visibility. Keys = ownerUserId.
function SceneBinder.syncHeroPlacePrompts(byOwner: {
    [number]: { [number]: SlotPromptState },
})
    for _, base in BaseLayout.getAll() do
        local map = _slotPrompts[base]
        if not map then
            continue
        end
        local ownerId = BaseLayout.getOwnerUserId(base) or 0
        local states = if ownerId > 0 then byOwner[ownerId] else nil
        for slotIndex = 1, Constants.SLOT_COUNT do
            local pair = map[slotIndex]
            if not pair then
                continue
            end
            if ownerId == 0 or states == nil then
                pair.place.Enabled = false
                pair.open.Enabled = false
                pair.skip.Enabled = false
                pair.pickup.Enabled = false
                pair.place.MaxActivationDistance = 0
                pair.open.MaxActivationDistance = 0
                pair.skip.MaxActivationDistance = 0
                pair.pickup.MaxActivationDistance = 0
                continue
            end
            local state = states[slotIndex]
            local occupied = state ~= nil and state.occupied == true
            local ready = state ~= nil and state.ready == true
            local packing = state ~= nil and state.packing == true
            local holding = state ~= nil and state.holding == true
            pair.place.Enabled = not occupied
            pair.open.Enabled = ready
            pair.skip.Enabled = packing
            pair.pickup.Enabled = holding
            pair.place.MaxActivationDistance = if occupied then 0 else 12
            pair.open.MaxActivationDistance = if ready then 12 else 0
            pair.skip.MaxActivationDistance = if packing then 12 else 0
            pair.pickup.MaxActivationDistance = if holding then 12 else 0
            if packing then
                pair.skip.ObjectText = skipRobuxLabel()
            end
        end
    end
end

return SceneBinder
