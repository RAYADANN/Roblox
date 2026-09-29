--!strict
-- Bind ProximityPrompts on Stands + HeroPlace Place/Open prompts.
-- Place/Open Enabled is synced from server so client gating cannot go stale.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)

export type Deps = {
    onRoll: (player: Player) -> (),
    onBuy: (player: Player, offerIndex: number) -> (),
    onPlace: (player: Player, slotIndex: number) -> (),
    onOpen: (player: Player, slotIndex: number) -> (),
}

export type SlotPromptState = {
    occupied: boolean,
    ready: boolean,
}

local SceneBinder = {}

local _slotPrompts: { [number]: { place: ProximityPrompt, open: ProximityPrompt } } = {}

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

function SceneBinder.install(deps: Deps)
    table.clear(_slotPrompts)

    local stands = Workspace:FindFirstChild("Stands")
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
                    prompt:SetAttribute("PromptKind", "buy")
                    prompt:SetAttribute("OfferIndex", i)
                    prompt.Triggered:Connect(function(player)
                        deps.onBuy(player, i)
                    end)
                end
            end
        end
    end

    local placeParts = HeroPlaceLayout.getOrderedPlaceParts()
    for slotIndex, placePart in placeParts do
        placePart:SetAttribute("SlotIndex", slotIndex)

        local placePrompt = remakePrompt(placePart, "PlacePrompt")
        placePrompt.ActionText = "Place"
        placePrompt.ObjectText = "Hero Place"
        placePrompt:SetAttribute("PromptKind", "place")
        placePrompt:SetAttribute("SlotIndex", slotIndex)
        placePrompt.Triggered:Connect(function(player)
            deps.onPlace(player, slotIndex)
        end)

        local openPrompt = remakePrompt(placePart, "OpenPrompt")
        openPrompt.ActionText = "Open"
        openPrompt.ObjectText = "Container"
        openPrompt.Enabled = false
        openPrompt:SetAttribute("PromptKind", "open")
        openPrompt:SetAttribute("SlotIndex", slotIndex)
        openPrompt.Triggered:Connect(function(player)
            deps.onOpen(player, slotIndex)
        end)

        _slotPrompts[slotIndex] = { place = placePrompt, open = openPrompt }
    end
end

-- Server-authoritative Place/Open visibility (shared pad indices 1..SLOT_COUNT).
function SceneBinder.syncHeroPlacePrompts(states: { [number]: SlotPromptState })
    for slotIndex = 1, Constants.SLOT_COUNT do
        local pair = _slotPrompts[slotIndex]
        if not pair then
            continue
        end
        local state = states[slotIndex]
        local occupied = state ~= nil and state.occupied == true
        local ready = state ~= nil and state.ready == true
        pair.place.Enabled = not occupied
        pair.open.Enabled = ready
        pair.place.MaxActivationDistance = if occupied then 0 else 12
        pair.open.MaxActivationDistance = if ready then 12 else 0
    end
end

return SceneBinder
