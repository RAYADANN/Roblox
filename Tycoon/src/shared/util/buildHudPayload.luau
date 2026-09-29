--!strict
-- PlayerData → HudPayload. Pure.

local Constants
local ExclusiveOfferLogic
local FarmLogic
local HudPayloadModule
local PlayerDataModule
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
    ExclusiveOfferLogic = require(script.Parent.ExclusiveOfferLogic)
    FarmLogic = require(script.Parent.FarmLogic)
    HudPayloadModule = require(script.Parent.Parent.types.HudPayload)
    PlayerDataModule = require(script.Parent.Parent.types.PlayerData)
else
    Constants = require("../data/Constants")
    ExclusiveOfferLogic = require("./ExclusiveOfferLogic")
    FarmLogic = require("./FarmLogic")
    HudPayloadModule = require("../types/HudPayload")
    PlayerDataModule = require("../types/PlayerData")
end

type PlayerData = PlayerDataModule.PlayerData
type HudPayload = HudPayloadModule.HudPayload

local buildHudPayload = {}

function buildHudPayload.fromPlayerData(
    data: PlayerData,
    multiplier: number?,
    maxSlots: number?
): HudPayload
    local unitCount = #data.units
    local cap = maxSlots or Constants.MAX_SLOTS
    local seenAt = data.exclusiveOfferSeenAt or 0
    return {
        coins = data.coins,
        pendingCash = data.pendingCash,
        backpackEggs = data.backpackEggs,
        luckyBlocks = data.luckyBlocks,
        shopQueue = data.shopQueue,
        processPerSec = FarmLogic.processPerSec(data.processLevel),
        multiplier = FarmLogic.clampMultiplier(multiplier or 1),
        unitCount = unitCount,
        emptySlots = FarmLogic.emptySlots(unitCount, cap),
        nextUnitCost = FarmLogic.unitCost(data.buyCount),
        rebirths = data.rebirths,
        autoCollectEggs = data.autoCollectEggs,
        autoCollectCash = data.autoCollectCash,
        doubleItems = data.doubleItems,
        indexMaxTier = data.indexMaxTier or 0,
        productionLevel = data.productionLevel,
        buyCount = data.buyCount,
        exclusiveOfferEndsAt = ExclusiveOfferLogic.endsAt(seenAt),
        exclusiveHeartOwned = data.exclusiveHeartOwned == true,
        exclusiveRebirthOwned = data.exclusiveRebirthOwned == true,
    }
end

return buildHudPayload
