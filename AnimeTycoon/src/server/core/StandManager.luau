--!strict
-- Personal stand offers (5). Buy → inventory (+ auto-equip hand).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoxVisualLogic = require(ReplicatedStorage.shared.util.BoxVisualLogic)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local ContainerModule = require(ReplicatedStorage.shared.types.Container)
local HeroCatalog = require(ReplicatedStorage.shared.data.HeroCatalog)
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

local function makeOffer(
    luckBias: number?,
    luckLevel: number?,
    luckMult: number?,
    _offerIndex: number
): StandOffer
    local rarity = MutationLogic.pickRarity(math.random(), luckBias, luckMult)
    local standLevel = BoxVisualLogic.standLevelFromLuck(luckLevel or 0)
    local boxModelName = ContainerLogic.pickBoxModelName(standLevel, math.random())
    local entry = RarityDatabase.get(rarity)
    local heroId = ContainerLogic.pickHeroId(rarity, math.random())
    local mutations = MutationLogic.normalizeStack(
        MutationLogic.rollOfferMutations(rarity, math.random(), math.random())
    )
    return {
        uid = HttpService:GenerateGUID(false),
        templateId = "stand" .. tostring(standLevel),
        boxModelName = boxModelName,
        rarity = rarity,
        heroId = heroId,
        displayName = HeroCatalog.displayName(heroId),
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
    local mutations = MutationLogic.normalizeStack(offer.mutations)
    return {
        uid = offer.uid,
        templateId = offer.templateId,
        boxModelName = offer.boxModelName,
        rarity = offer.rarity,
        heroId = offer.heroId,
        displayName = offer.displayName,
        baseIncome = offer.baseIncome,
        mutations = mutations,
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
        local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
        local BoostOfferLogic = require(ReplicatedStorage.shared.util.BoostOfferLogic)
        local luckBias = UpgradeLogic.luckBias(data.upgrades)
        local luckMult = BoostOfferLogic.luckMultiplier(data)
        local luckLevel = if data.upgrades then (data.upgrades.luck or 0) else 0
        local unlocked = UpgradeLogic.unlockedPads(data.upgrades)
        local offers: { StandOffer } = table.create(Constants.OFFER_COUNT)
        for i = 1, Constants.OFFER_COUNT do
            if i <= unlocked then
                offers[i] = makeOffer(luckBias, luckLevel, luckMult, i)
            else
                offers[i] = emptyOfferSlot()
            end
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
        local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
        if not UpgradeLogic.isPadUnlocked(d.upgrades, idx) then
            failReason = "pad_locked"
            return
        end
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
        local price =
            ContainerLogic.buyPrice(offer.rarity, #(MutationLogic.normalizeStack(offer.mutations)))
        if d.coins < price then
            failReason = "cannot_afford"
            return
        end
        d.coins -= price
        local instance = offerToInstance(offer)
        if d.firstContainerBought ~= true then
            instance.fastUnpack = true
            d.firstContainerBought = true
        end
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

--- Set / clear equipped inventory uid (Place uses handUid).
function StandManager:setHand(player: Player, uid: string): (boolean, string?)
    local pm = self._deps.profileManager
    local data = pm:get(player)
    if not data then
        return false, "no_profile"
    end

    if uid == "" then
        local cleared = pm:mutate(player, function(d: PlayerData)
            d.handUid = nil
        end)
        if not cleared then
            return false, "no_profile"
        end
        return true, nil
    end

    local found = false
    for _, item in data.inventory or {} do
        if item.uid == uid then
            found = true
            break
        end
    end
    if not found then
        return false, "not_in_inventory"
    end

    local ok = pm:mutate(player, function(d: PlayerData)
        local stillThere = false
        for _, item in d.inventory or {} do
            if item.uid == uid then
                stillThere = true
                break
            end
        end
        if not stillThere then
            return
        end
        d.handUid = uid
    end)
    if not ok then
        return false, "no_profile"
    end
    local after = pm:get(player)
    if after == nil or after.handUid ~= uid then
        return false, "not_in_inventory"
    end
    return true, nil
end

return StandManager
