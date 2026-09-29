--!strict
-- Personal dispenser offers (3). Buy → inventory (+ auto-equip hand).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local ExhibitCatalog = require(ReplicatedStorage.shared.data.ExhibitCatalog)
local ExhibitLogic = require(ReplicatedStorage.shared.util.ExhibitLogic)
local ExhibitModule = require(ReplicatedStorage.shared.types.Exhibit)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)
local RarityDatabase = require(ReplicatedStorage.shared.data.RarityDatabase)
local WorldCosmeticPublisher = require(script.Parent.WorldCosmeticPublisher)

type PlayerData = PlayerDataModule.PlayerData
type DispenserOffer = ExhibitModule.DispenserOffer
type ExhibitInstance = ExhibitModule.ExhibitInstance

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
}

local DispenserManager = {}
DispenserManager.__index = DispenserManager

local function makeOffer(): DispenserOffer
    local rarity = MutationLogic.pickRarity(math.random())
    local templateId = MutationLogic.pickTemplate(math.random())
    local template = ExhibitCatalog.byId[templateId]
    local entry = RarityDatabase.get(rarity)
    local sizeId = ExhibitLogic.rollSize(math.random())
    local baseName = if template then template.displayName else "Exhibit"
    local mutations = MutationLogic.rollEggMutations(rarity, math.random(), math.random())
    return {
        uid = HttpService:GenerateGUID(false),
        templateId = templateId,
        rarity = rarity,
        sizeId = sizeId,
        styleId = if template then template.styleId else "cube_teal",
        characterId = if template then template.characterId else "calm",
        displayName = baseName,
        baseIncome = if entry then entry.baseIncomePerSec else 5,
        mutations = mutations,
    }
end

-- Dense empty slot so pad indices survive ProfileStore JSON (no nil holes).
local function emptyOfferSlot(): DispenserOffer
    return {
        uid = "",
        templateId = "",
        rarity = "common",
        sizeId = "medium",
        styleId = "cube_teal",
        characterId = "calm",
        displayName = "",
        baseIncome = 0,
        mutations = {},
    }
end

local function isLiveOffer(offer: DispenserOffer?): boolean
    return offer ~= nil and offer.uid ~= ""
end

local function offerToInstance(offer: DispenserOffer): ExhibitInstance
    local mutations = offer.mutations or {}
    local stacks = #mutations
    return {
        uid = offer.uid,
        templateId = offer.templateId,
        rarity = offer.rarity,
        sizeId = offer.sizeId or "medium",
        styleId = offer.styleId,
        characterId = offer.characterId,
        displayName = offer.displayName,
        baseIncome = offer.baseIncome,
        attention = 0,
        placedAt = nil,
        slotIndex = nil,
        evolveProgress = 0,
        evolved = false,
        mutated = stacks > 0,
        mutations = table.clone(mutations),
        mutationStacks = stacks,
        npcBase = 0,
        npcShunned = false,
        celebrateUntil = 0,
        celebrateKind = "",
        animId = "spin",
        incomeRate = offer.baseIncome,
    }
end

function DispenserManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, DispenserManager)
end

function DispenserManager:refreshOffers(player: Player): boolean
    local pm = (self :: any)._deps.profileManager
    return pm:mutate(player, function(data: PlayerData)
        local offers: { DispenserOffer } = table.create(ExhibitCatalog.OFFER_COUNT)
        for i = 1, ExhibitCatalog.OFFER_COUNT do
            offers[i] = makeOffer()
        end
        data.offers = offers
        data.offersGeneratedAt = os.time()
    end)
end

function DispenserManager:ensureOffers(player: Player)
    local pm = (self :: any)._deps.profileManager
    local data = pm:get(player)
    if not data then
        return
    end
    -- First join only. Bought pads stay empty until Spin (refreshOffers).
    if data.offersGeneratedAt == 0 then
        self:refreshOffers(player)
    end
end

function DispenserManager:pickOffer(player: Player, offerUid: string): (boolean, string?)
    if typeof(offerUid) ~= "string" or offerUid == "" then
        return false, "invalid_offer"
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

    local picked = false
    local failReason: string? = nil
    local ok = pm:mutate(player, function(d: PlayerData)
        if not d.inventory then
            d.inventory = {}
        end
        if #d.inventory >= Constants.INVENTORY_MAX then
            failReason = "inventory_full"
            return
        end
        local index: number? = nil
        for i = 1, ExhibitCatalog.OFFER_COUNT do
            local o = d.offers[i]
            if o and o.uid == offerUid and o.uid ~= "" then
                index = i
                break
            end
        end
        if index == nil then
            failReason = "offer_missing"
            return
        end
        local offer = d.offers[index :: number] :: DispenserOffer
        local price = ExhibitLogic.buyPrice(offer.rarity, offer.sizeId, #(offer.mutations or {}))
        if d.coins < price then
            failReason = "not_enough_coins"
            return
        end
        d.coins -= price
        d.offers[index :: number] = emptyOfferSlot()
        local instance = offerToInstance(offer)
        table.insert(d.inventory, instance)
        if d.handUid == nil or d.handUid == "" then
            d.handUid = instance.uid
        end
        picked = true
    end)

    if not ok then
        return false, "mutate_failed"
    end
    if not picked then
        return false, failReason or "offer_missing"
    end
    WorldCosmeticPublisher.syncHeldEgg(player, pm:get(player))
    return true, nil
end

function DispenserManager:pickOfferByIndex(player: Player, offerIndex: number): (boolean, string?)
    if typeof(offerIndex) ~= "number" or offerIndex ~= math.floor(offerIndex) then
        return false, "invalid_index"
    end
    if offerIndex < 1 or offerIndex > ExhibitCatalog.OFFER_COUNT then
        return false, "invalid_index"
    end
    local pm = (self :: any)._deps.profileManager
    local data = pm:get(player)
    if not data then
        return false, "no_profile"
    end
    local offer = data.offers[offerIndex]
    if not isLiveOffer(offer) then
        return false, "offer_missing"
    end
    return self:pickOffer(player, offer.uid)
end

return DispenserManager
