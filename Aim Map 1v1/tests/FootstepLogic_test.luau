local FootstepLogic = require("@shared/util/FootstepLogic")

return {
    ["shouldAccumulate requires ground and speed"] = function(expect)
        expect(FootstepLogic.shouldAccumulate(10, 2.5, true)).toEqual(true)
        expect(FootstepLogic.shouldAccumulate(1, 2.5, true)).toEqual(false)
        expect(FootstepLogic.shouldAccumulate(10, 2.5, false)).toEqual(false)
    end,
    ["consumeStrides returns whole steps and remainder"] = function(expect)
        local steps, rem = FootstepLogic.consumeStrides(7.5, 2.5)
        expect(steps).toEqual(3)
        expect(rem).toBeCloseTo(0, 1e-6)
        local steps2, rem2 = FootstepLogic.consumeStrides(3.2, 2.6)
        expect(steps2).toEqual(1)
        expect(rem2).toBeCloseTo(0.6, 1e-6)
    end,
}
