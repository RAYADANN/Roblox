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
    ["valueMultiplier: +10% за ребёрт (float → toBeCloseTo)"] = function(expect)
        expect(RebirthLogic.valueMultiplier(3)).toBeCloseTo(1.3)
    end,
}
