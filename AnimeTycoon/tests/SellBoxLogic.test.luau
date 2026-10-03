--!strict

local SellBoxLogic = require("../src/shared/util/SellBoxLogic")

return {
    ["fill01 starts at 0"] = function(expect)
        expect(SellBoxLogic.fill01(0)).toEqual(0)
    end,
    ["no growth until toysPerStep"] = function(expect)
        local base = 1
        local step = SellBoxLogic.toysPerStep()
        expect(SellBoxLogic.sizeX(base, step - 1)).toEqual(base)
        expect(SellBoxLogic.growthSteps(step - 1)).toEqual(0)
        expect(SellBoxLogic.growthSteps(step)).toEqual(1)
        expect(SellBoxLogic.sizeX(base, step) > base).toBeTruthy()
    end,
    ["fill01 grows and asymptotes under 1"] = function(expect)
        local a = SellBoxLogic.fill01(12)
        local b = SellBoxLogic.fill01(48)
        expect(a > 0).toBeTruthy()
        expect(b > a).toBeTruthy()
        expect(b < 1).toBeTruthy()
    end,
    ["sizeX grows from base"] = function(expect)
        local base = 1.3
        local empty = SellBoxLogic.sizeX(base, 0)
        local grown = SellBoxLogic.sizeX(base, 200)
        expect(empty).toEqual(base)
        expect(grown > empty).toBeTruthy()
        expect(grown <= base * SellBoxLogic.maxSizeMult() + 1e-6).toBeTruthy()
    end,
    ["max mult is half of prior sky curve"] = function(expect)
        expect(SellBoxLogic.maxSizeMult()).toEqual(14)
    end,
    ["canPickup requires coins"] = function(expect)
        expect(SellBoxLogic.canPickup(SellBoxLogic.emptyActive())).toBeFalsy()
        expect(SellBoxLogic.canPickup({ coins = 10, depositCount = 1 })).toBeTruthy()
    end,
    ["deposit adds coins and toys"] = function(expect)
        local nextBox = SellBoxLogic.deposit(SellBoxLogic.emptyActive(), 7.5, 1)
        expect(nextBox.coins).toEqual(7.5)
        expect(nextBox.depositCount).toEqual(1)
    end,
    ["totalCrateCoins sums inventory"] = function(expect)
        local sum = SellBoxLogic.totalCrateCoins({
            { uid = "a", coins = 10, depositCount = 2 },
            { uid = "b", coins = 5.5, depositCount = 1 },
        })
        expect(sum).toEqual(15.5)
    end,
}
