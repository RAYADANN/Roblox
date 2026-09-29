--!strict
-- Юнит-тест чистой логики. Относительный require — чтобы гонялось под Lune без Studio.
local RebirthLogic = require("../src/shared/util/RebirthLogic")

return {
    ["cost: базовая стоимость на 0 ребёртов"] = function(expect)
        expect(RebirthLogic.cost(0)).toEqual(50000)
    end,
    ["cost: растёт как base * 5^n"] = function(expect)
        expect(RebirthLogic.cost(1)).toEqual(250000)
        expect(RebirthLogic.cost(2)).toEqual(1250000)
    end,
    ["valueMultiplier: без ребёртов = 1"] = function(expect)
        expect(RebirthLogic.valueMultiplier(0)).toEqual(1)
    end,
    ["valueMultiplier: +1 за ребёрт (MULT_PER=1)"] = function(expect)
        expect(RebirthLogic.valueMultiplier(3)).toEqual(4)
    end,
    ["canAfford: false below cost"] = function(expect)
        expect(RebirthLogic.canAfford(49999, 0)).toBe(false)
    end,
    ["canAfford: true at cost"] = function(expect)
        expect(RebirthLogic.canAfford(50000, 0)).toBe(true)
    end,
    ["progress: caps at need"] = function(expect)
        local have, need = RebirthLogic.progress(999999, 0)
        expect(have).toEqual(50000)
        expect(need).toEqual(50000)
    end,
    ["progressFraction: half"] = function(expect)
        expect(RebirthLogic.progressFraction(25000, 0)).toBeCloseTo(0.5)
    end,
    ["coinRewardLabel: next mult"] = function(expect)
        expect(RebirthLogic.coinRewardLabel(0)).toEqual("X2 Coins")
        expect(RebirthLogic.coinRewardLabel(1)).toEqual("X3 Coins")
    end,
}
