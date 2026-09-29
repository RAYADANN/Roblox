--!strict
-- Personal stand offers (5). Buy → inventory (+ auto-equip hand).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContainerCatalog = require(ReplicatedStorage.shared.data.ContainerCatalog)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local ContainerModule = require(ReplicatedStorage.shared.types.Container)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)
local RarityDatabase = require(ReplicatedStorage.shared.data.RarityDatabase)

type PlayerData = PlayerDataModule.PlayerData
type StandOffer = ContainerModule.StandOffer
type ContainerInstance = ContainerModule.ContainerInstance

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
}

local StandManager = {}
StandManager.__index = StandManager

local function makeOffer(): StandOffer
    local rarity = MutationLogic.pickRarity(math.random())
    local templateId = ContainerLogic.pickTemplateId(math.random())
    local template = ContainerCatalog.get(templateId)
    local entry = RarityDatabase.get(rarity)
    local heroId = ContainerLogic.pickHeroId(templateId, math.random())
    local mutations = MutationLogic.rollOfferMutations(rarity, math.random(), math.random())
    return {
        uid = HttpService:GenerateGUID(false),
        templateId = templateId,
        boxModelName = if template then template.boxModelName else "Box1",
        rarity = rarity,
        heroId = heroId,
        displayName = if template then template.displayName else "Toy Box",
        baseIncome = if entry then entry.baseIncomePerMini else 5,
        mutations = mutations,
    }
end

local function emptyOfferSlot(): StandOffer
    return {
        uid = "",
        templateId = "",
        boxModelName = "",
        rarity = "common",
        heroId = "",
        displayName = "",
        baseIncome = 0,
        mutations = {},
    }
end

local function offerToInstance(offer: StandOffer): ContainerInstance
    local mutations = offer.mutations or {}
    return {
        uid = offer.uid,
        templateId = offer.templateId,
        boxModelName = offer.boxModelName,
        rarity = offer.rarity,
        heroId = offer.heroId,
        displayName = offer.displayName,
        baseIncome = offer.baseIncome,
        mutations = table.clone(mutations),
        placedAt = nil,
        slotIndex = nil,
        unpackProgress = 0,
        unpacked = false,
        incomeRate = ContainerLogic.incomePerMini(offer.rarity, mutations),
    }
end

function StandManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, StandManager)
end

function StandManager:refreshOffers(player: Player): boolean
    local pm = (self :: any)._deps.profileManager
    return pm:mutate(player, function(data: PlayerData)
        local offers: { StandOffer } = table.create(Constants.OFFER_COUNT)
        for i = 1, Constants.OFFER_COUNT do
            offers[i] = makeOffer()
        end
        data.offers = offers
        data.offersGeneratedAt = os.time()
    end)
end

function StandManager:ensureOffers(player: Player)
    local pm = (self :: any)._deps.profileManager
    local data = pm:get(player)
    if not data then
        return
    end
    if data.offersGeneratedAt == 0 then
        self:refreshOffers(player)
    end
end

function StandManager:buyOfferByIndex(player: Player, offerIndex: number): (boolean, string?)
    if typeof(offerIndex) ~= "number" then
        return false, "invalid_index"
    end
    local idx = math.floor(offerIndex)
    if idx < 1 or idx > Constants.OFFER_COUNT then
        return false, "invalid_index"
    end

    local pm = (self :: any)._deps.profileManager
    local data = pm:get(player)
    if not data then
        return false, "no_profile"
    end
    if not data.inventory then
        data.inventory = {}
    end
    if #data.inventory >= Constants.INVENTORY_MAX then
        return false, "inventory_full"
    end

    local failReason: string? = nil
    local ok = pm:mutate(player, function(d: PlayerData)
        if not d.inventory then
            d.inventory = {}
        end
        if #d.inventory >= Constants.INVENTORY_MAX then
            failReason = "inventory_full"
            return
        end
        local offer = d.offers[idx]
        if not offer or offer.uid == "" then
            failReason = "empty_offer"
            return
        end
        local price = ContainerLogic.buyPrice(offer.rarity, #(offer.mutations or {}))
        if d.coins < price then
            failReason = "cannot_afford"
            return
        end
        d.coins -= price
        local instance = offerToInstance(offer)
        table.insert(d.inventory, instance)
        if d.handUid == nil or d.handUid == "" then
            d.handUid = instance.uid
        end
        d.offers[idx] = emptyOfferSlot()
    end)

    if not ok then
        return false, "no_profile"
    end
    if failReason then
        return false, failReason
    end
    return true, nil
end

return StandManager
