return {
    ["stepDelays ease in"] = function(expect)
        local OfferRouletteLogic = require("../src/shared/util/OfferRouletteLogic")
        local d = OfferRouletteLogic.stepDelays({ steps = 5 })
        expect(#d).toEqual(5)
        expect(d[1] < d[5]).toBeTruthy()
    end,
    ["totalDuration includes stagger"] = function(expect)
        local OfferRouletteLogic = require("../src/shared/util/OfferRouletteLogic")
        local d = OfferRouletteLogic.stepDelays({ steps = 3, startDelay = 0.1, endDelay = 0.1 })
        local t1 = OfferRouletteLogic.totalDuration(d, 0.2, 1)
        local t3 = OfferRouletteLogic.totalDuration(d, 0.2, 3)
        expect(t3 > t1).toBeTruthy()
    end,
}
