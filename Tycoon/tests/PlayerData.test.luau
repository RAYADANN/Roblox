--!strict
local PlayerData = require("../src/shared/types/PlayerData")

return {
    ["applyTemplate wipes progress to starter coins"] = function(expect)
        local data = {
            coins = 99999,
            pendingCash = 10,
            backpackEggs = 40,
            luckyBlocks = 2,
            shopQueue = 80,
            processLevel = 3,
            productionLevel = 2,
            units = { 5, 5, 4 },
            buyCount = 20,
            autoCollectEggs = true,
            autoCollectCash = true,
            doubleItems = true,
            lastSeenAt = 123,
            groupRewardAt = 99,
            rebirths = 4,
            indexMaxTier = 6,
            upgrades = { pickaxe = 2 },
            firstSessionComplete = true,
            grantedPurchases = { abc = true },
            exclusiveOfferSeenAt = 555,
        }
        PlayerData.applyTemplate(data)
        expect(data.coins).toEqual(PlayerData.TEMPLATE.coins)
        expect(data.backpackEggs).toEqual(0)
        expect(#data.units).toEqual(0)
        expect(data.rebirths).toEqual(0)
        expect(data.autoCollectEggs).toEqual(false)
        expect(data.autoCollectCash).toEqual(false)
        expect(data.doubleItems).toEqual(false)
        expect(data.buyCount).toEqual(0)
        expect(data.indexMaxTier).toEqual(0)
        expect(data.grantedPurchases.abc).toEqual(nil)
        expect(data.exclusiveOfferSeenAt).toEqual(555)
    end,
}
