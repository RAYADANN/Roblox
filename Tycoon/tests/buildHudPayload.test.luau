return {
    ["maps player data to hud"] = function(expect)
        local buildHudPayload = require("../src/shared/util/buildHudPayload")
        local payload = buildHudPayload.fromPlayerData({
            coins = 12,
            pendingCash = 3,
            backpackEggs = 8,
            luckyBlocks = 1,
            shopQueue = 20,
            processLevel = 2,
            productionLevel = 0,
            units = { 1, 1 },
            buyCount = 2,
            autoCollectEggs = false,
            autoCollectCash = true,
            doubleItems = false,
            lastSeenAt = 0,
            groupRewardAt = 0,
            rebirths = 1,
            indexMaxTier = 2,
            upgrades = {},
            firstSessionComplete = true,
            grantedPurchases = {},
            exclusiveOfferSeenAt = 0,
            exclusiveHeartOwned = false,
            exclusiveRebirthOwned = false,
        }, 1.2)
        expect(payload.coins).toEqual(12)
        expect(payload.unitCount).toEqual(2)
        expect(payload.processPerSec).toBeCloseTo(4, 1e-6)
        expect(payload.multiplier).toEqual(1.2)
        expect(payload.autoCollectCash).toEqual(true)
        expect(payload.emptySlots).toEqual(38)
        expect(payload.indexMaxTier).toEqual(2)
        expect(payload.productionLevel).toEqual(0)
        expect(payload.buyCount).toEqual(2)
        expect(payload.exclusiveOfferEndsAt).toEqual(0)
        expect(payload.exclusiveHeartOwned).toEqual(false)
        expect(payload.exclusiveRebirthOwned).toEqual(false)
    end,

    ["emptySlots uses DummyItems count"] = function(expect)
        local buildHudPayload = require("../src/shared/util/buildHudPayload")
        local payload = buildHudPayload.fromPlayerData({
            coins = 1,
            pendingCash = 0,
            backpackEggs = 0,
            luckyBlocks = 0,
            shopQueue = 0,
            processLevel = 0,
            productionLevel = 0,
            units = { 1, 1 },
            buyCount = 2,
            autoCollectEggs = false,
            autoCollectCash = false,
            doubleItems = false,
            lastSeenAt = 0,
            groupRewardAt = 0,
            rebirths = 0,
            indexMaxTier = 0,
            upgrades = {},
            firstSessionComplete = true,
            grantedPurchases = {},
            exclusiveOfferSeenAt = 0,
            exclusiveHeartOwned = false,
            exclusiveRebirthOwned = false,
        }, 1, 6)
        expect(payload.emptySlots).toEqual(4)
    end,
}
