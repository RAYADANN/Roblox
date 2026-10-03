--!strict
-- PlayerData → HudPayload. Pure, testable.

local BoxVisualLogic
local BoostOfferLogic
local HeroCatalog
local HudPayloadModule
local PlayerDataModule
local HeroLevelLogic
local ContainerLogic
local MutationLogic
local Constants
local SlotMap
if script and script.Parent then
    BoxVisualLogic = require(script.Parent.BoxVisualLogic)
    BoostOfferLogic = require(script.Parent.BoostOfferLogic)
    HeroCatalog = require(script.Parent.Parent.data.HeroCatalog)
    HudPayloadModule = require(script.Parent.Parent.types.HudPayload)
    PlayerDataModule = require(script.Parent.Parent.types.PlayerData)
    HeroLevelLogic = require(script.Parent.HeroLevelLogic)
    ContainerLogic = require(script.Parent.ContainerLogic)
    MutationLogic = require(script.Parent.MutationLogic)
    Constants = require(script.Parent.Parent.data.Constants)
    SlotMap = require(script.Parent.SlotMap)
else
    BoxVisualLogic = require("./BoxVisualLogic")
    BoostOfferLogic = require("./BoostOfferLogic")
    HeroCatalog = require("../data/HeroCatalog")
    HudPayloadModule = require("../types/HudPayload")
    PlayerDataModule = require("../types/PlayerData")
    HeroLevelLogic = require("./HeroLevelLogic")
    ContainerLogic = require("./ContainerLogic")
    MutationLogic = require("./MutationLogic")
    Constants = require("../data/Constants")
    SlotMap = require("./SlotMap")
end

type PlayerData = PlayerDataModule.PlayerData
type HudPayload = HudPayloadModule.HudPayload

local buildHudPayload = {}

function buildHudPayload.fromPlayerData(data: PlayerData): HudPayload
    local offers = {}
    for _, offer in data.offers or {} do
        if offer.uid ~= "" then
            local muts = MutationLogic.normalizeStack(offer.mutations)
            table.insert(offers, {
                uid = offer.uid,
                templateId = offer.templateId,
                boxModelName = offer.boxModelName,
                rarity = offer.rarity,
                heroId = offer.heroId,
                displayName = BoxVisualLogic.formatCaseDisplayName(offer.boxModelName or ""),
                baseIncome = offer.baseIncome,
                buyPrice = ContainerLogic.buyPrice(offer.rarity, #muts),
                mutationLabel = MutationLogic.formatLabel(muts),
            })
        else
            table.insert(offers, {
                uid = "",
                templateId = "",
                boxModelName = "",
                rarity = "common",
                heroId = "",
                displayName = "",
                baseIncome = 0,
                buyPrice = 0,
                mutationLabel = "",
            })
        end
    end

    local slots = {}
    local slotList = data.slots or {}
    for i = 1, Constants.SLOT_COUNT do
        local slot = SlotMap.get(slotList, i)
        if slot then
            local muts = MutationLogic.normalizeStack(slot.mutations)
            local level = HeroLevelLogic.normalize(slot.level)
            local levelCost = 0
            if slot.unpacked == true then
                local base =
                    HeroLevelLogic.basePerMini(slot.rarity, slot.mutations, slot.baseIncome)
                levelCost = HeroLevelLogic.upgradeCost(
                    base,
                    ContainerLogic.produceInterval(slot.rarity),
                    level
                ) or 0
            end
            table.insert(slots, {
                uid = slot.uid,
                templateId = slot.templateId,
                boxModelName = slot.boxModelName,
                rarity = slot.rarity,
                heroId = slot.heroId,
                displayName = if slot.unpacked
                    then HeroCatalog.displayName(slot.displayName or slot.heroId or "")
                    else BoxVisualLogic.formatCaseDisplayName(slot.boxModelName or ""),
                unpackProgress = slot.unpackProgress,
                unpacked = slot.unpacked,
                mutationLabel = MutationLogic.formatLabel(muts),
                incomeRate = slot.incomeRate,
                slotIndex = slot.slotIndex or i,
                level = level,
                levelCost = levelCost,
            })
        end
    end

    local inventory = {}
    for _, item in data.inventory or {} do
        local muts = MutationLogic.normalizeStack(item.mutations)
        local sealed = item.unpacked ~= true
        table.insert(inventory, {
            uid = item.uid,
            displayName = if sealed
                then BoxVisualLogic.formatCaseDisplayName(item.boxModelName or "")
                else HeroCatalog.displayName(item.displayName or item.heroId or ""),
            rarity = item.rarity,
            boxModelName = item.boxModelName,
            mutationLabel = MutationLogic.formatLabel(muts),
            heroId = item.heroId or "",
            templateId = item.templateId or "",
            unpacked = item.unpacked == true,
            mutations = muts,
        })
    end

    local active = data.activeSellBox or { coins = 0, depositCount = 0 }
    local sellCrates = {}
    for _, crate in data.sellCrates or {} do
        table.insert(sellCrates, {
            uid = crate.uid,
            coins = crate.coins,
            depositCount = crate.depositCount,
        })
    end

    return {
        coins = data.coins,
        rebirths = data.rebirths,
        upgrades = table.clone(data.upgrades),
        handUid = data.handUid,
        offers = offers,
        slots = slots,
        inventory = inventory,
        sellBoxCoins = active.coins or 0,
        sellBoxDeposits = active.depositCount or 0,
        sellCrates = sellCrates,
        indexFound = table.clone(data.indexFound or {}),
        rewardTrackStartedAt = 0,
        rewardClaimed = {},
        tutorialCompleted = data.tutorialCompleted == true,
        boostOfferEndsAt = BoostOfferLogic.endsAt(data.boostOfferSeenAt or 0),
        ownsLuckyX2 = data.ownsLuckyX2 == true,
        ownsLuckyX4 = data.ownsLuckyX4 == true,
        ownsMoneyX2 = data.ownsMoneyX2 == true,
        pendingOfflineCoins = math.max(0, tonumber(data.pendingOfflineCoins) or 0),
    }
end

return buildHudPayload
