--!strict
local HeroScaleLogic = require("../src/shared/util/HeroScaleLogic")

return {
    ["factor scales by height"] = function(expect)
        local f = HeroScaleLogic.factor({ X = 2, Y = 10, Z = 2 }, 5, nil)
        expect(f).toBeCloseTo(0.5, 5)
    end,
    ["factor clamps by max extent"] = function(expect)
        -- height wants 2x, but max extent wants 0.5x → 0.5
        local f = HeroScaleLogic.factor({ X = 20, Y = 5, Z = 2 }, 10, 10)
        expect(f).toBeCloseTo(0.5, 5)
    end,
    ["tiny height uses floor"] = function(expect)
        local f = HeroScaleLogic.factor({ X = 1, Y = 0.01, Z = 1 }, 5, nil)
        expect(f).toBeCloseTo(100, 5)
    end,
}
