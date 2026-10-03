--!strict
-- Limited RobStand hero billboards: rarity + mutation ColorSheen (same as world heroes).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local LimitedLogic = require(ReplicatedStorage.shared.util.LimitedLogic)
local LimitedOfferDatabase = require(ReplicatedStorage.shared.data.LimitedOfferDatabase)
local MutationShine = require(script.Parent.MutationShine)
local RarityShine = require(script.Parent.RarityShine)
local RarityShineDatabase = require(ReplicatedStorage.shared.data.RarityShineDatabase)

local LimitedStandVisual = {}

local function findLabel(root: Instance, name: string): TextLabel?
    local direct = root:FindFirstChild(name, true)
    if direct and direct:IsA("TextLabel") then
        return direct
    end
    return nil
end

--- Billboard under the hero model (has Rare/Mutation), not the stock Count board.
local function findHeroBillboard(stand: Instance): BillboardGui?
    for _, d in stand:GetDescendants() do
        if d:IsA("BillboardGui") then
            local rare = findLabel(d, "Rare")
            local mutation = findLabel(d, "Mutation")
            if rare ~= nil or mutation ~= nil then
                return d
            end
        end
    end
    return nil
end

local function ensureBlackStroke(label: TextLabel)
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if stroke == nil then
        stroke = Instance.new("UIStroke")
        stroke.Parent = label
    end
    stroke.Color = Color3.new(0, 0, 0)
    stroke.LineJoinMode = Enum.LineJoinMode.Bevel
end

local function applyStand(stand: Instance, offer: LimitedOfferDatabase.LimitedOffer)
    local bb = findHeroBillboard(stand)
    if not bb then
        return
    end
    bb.MaxDistance = 0

    local rare = findLabel(bb, "Rare")
    if rare then
        -- Prefer authored Rare text when it has a shine def (e.g. Limited "Null").
        local authored = rare.Text
        local rarityKey = offer.rarity
        if typeof(authored) == "string" and authored ~= "" then
            if RarityShineDatabase.resolve(authored) then
                rarityKey = authored
            end
        end
        RarityShine.apply(rare, rarityKey)
        ensureBlackStroke(rare)
    end

    local mutation = findLabel(bb, "Mutation")
    if mutation then
        local raw = if #offer.mutations > 0 then offer.mutations[1] else ""
        local mutId = LimitedLogic.normalizeMutationId(raw) or raw
        if mutId ~= "" then
            MutationShine.apply(mutation, mutId)
            ensureBlackStroke(mutation)
        else
            MutationShine.unbind(mutation)
        end
    end

    local nameLabel = findLabel(bb, "NameLabel")
    if nameLabel then
        ensureBlackStroke(nameLabel)
    end
end

function LimitedStandVisual.start()
    local limited = BaseLayout.getLimited()
    if not limited then
        return
    end
    for _, offer in LimitedOfferDatabase.all() do
        local stand = limited:FindFirstChild(offer.standId)
        if stand then
            applyStand(stand, offer)
        end
    end
end

return LimitedStandVisual
