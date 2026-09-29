--!strict
-- Юнит-тест чистой логики. Относительный require — чтобы гонялось под Lune без Studio.
local Constants = require("../src/shared/data/Constants")
local PlayerData = require("../src/shared/types/PlayerData")
local RebirthDatabase = require("../src/shared/data/RebirthDatabase")
local RebirthLogic = require("../src/shared/util/RebirthLogic")

return {
    ["cost: first rebirth is 1000 cash"] = function(expect)
        expect(RebirthLogic.cost(0)).toEqual(1000)
    end,
    ["cost: follows cash table, not mining exponential"] = function(expect)
        expect(RebirthLogic.cost(1)).toEqual(25_000)
        expect(RebirthLogic.cost(2)).toEqual(500_000)
    end,
    ["valueMultiplier: no rebirths = 1"] = function(expect)
        expect(RebirthLogic.valueMultiplier(0)).toEqual(1)
    end,
    ["valueMultiplier: first rebirth is X2 cash"] = function(expect)
        expect(RebirthLogic.valueMultiplier(1)).toEqual(2)
        expect(RebirthLogic.valueMultiplier(2)).toEqual(5)
    end,
    ["canAfford: true when coins >= cash requirement"] = function(expect)
        expect(RebirthLogic.canAfford(1000, 0)).toEqual(true)
        expect(RebirthLogic.canAfford(999, 0)).toEqual(false)
    end,
    ["progress: caps at cash requirement"] = function(expect)
        local have, need = RebirthLogic.progress(1500, 0)
        expect(have).toEqual(1000)
        expect(need).toEqual(1000)
        local have2, need2 = RebirthLogic.progress(250, 0)
        expect(have2).toEqual(250)
        expect(need2).toEqual(1000)
    end,
    ["progressFraction: 0..1"] = function(expect)
        expect(RebirthLogic.progressFraction(0, 0)).toEqual(0)
        expect(RebirthLogic.progressFraction(500, 0)).toBeCloseTo(0.5)
        expect(RebirthLogic.progressFraction(1000, 0)).toEqual(1)
    end,
    ["rewardLabel: next cash multiplier text"] = function(expect)
        expect(RebirthLogic.rewardLabel(0)).toEqual("X2 Coins")
        expect(RebirthLogic.rewardLabel(1)).toEqual("X5 Coins")
    end,
    ["overflow: beyond table still grows"] = function(expect)
        local lastIndex = #RebirthDatabase.Tiers
        local lastCost = RebirthLogic.cost(lastIndex - 1)
        local overflowCost = RebirthLogic.cost(lastIndex)
        expect(overflowCost > lastCost).toEqual(true)
        local lastMult = RebirthLogic.valueMultiplier(lastIndex)
        local overflowMult = RebirthLogic.valueMultiplier(lastIndex + 1)
        expect(overflowMult > lastMult).toEqual(true)
    end,
    ["apply: increments rebirths and resets farm progress"] = function(expect)
        local data = table.clone(PlayerData.TEMPLATE)
        data.coins = 1000
        data.units = { 3, 2, 1 }
        data.buyCount = 12
        data.processLevel = 2
        data.productionLevel = 1
        data.backpackEggs = 40
        data.pendingCash = 100
        data.shopQueue = 5
        data.luckyBlocks = 2
        data.upgrades = { dig = 1 }
        data.autoCollectEggs = true
        data.doubleItems = true
        data.rebirths = 0
        data.indexMaxTier = 5

        RebirthLogic.apply(data)

        expect(data.rebirths).toEqual(1)
        expect(data.coins).toEqual(Constants.START_COINS)
        expect(#data.units).toEqual(0)
        expect(data.buyCount).toEqual(0)
        expect(data.processLevel).toEqual(0)
        expect(data.productionLevel).toEqual(0)
        expect(data.backpackEggs).toEqual(0)
        expect(data.pendingCash).toEqual(0)
        expect(data.shopQueue).toEqual(0)
        expect(data.luckyBlocks).toEqual(0)
        expect(next(data.upgrades)).toEqual(nil)
        expect(data.autoCollectEggs).toEqual(true)
        expect(data.doubleItems).toEqual(true)
        expect(data.indexMaxTier).toEqual(5)
    end,
}
