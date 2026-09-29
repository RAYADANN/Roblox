--!strict
local OfferRouletteLogic = require("../src/shared/util/OfferRouletteLogic")

return {
    ["stepDelays: length and monotonic slowdown"] = function(expect)
        local delays =
            OfferRouletteLogic.stepDelays({ steps = 10, startDelay = 0.05, endDelay = 0.4 })
        expect(#delays).toEqual(10)
        expect(delays[1] < delays[#delays]).toBeTruthy()
        expect(delays[1]).toBeCloseTo(0.05, 0.001)
        expect(delays[#delays]).toBeCloseTo(0.4, 0.001)
    end,
    ["totalDuration includes stagger"] = function(expect)
        local delays = { 0.1, 0.2, 0.3 }
        local d1 = OfferRouletteLogic.totalDuration(delays, 0.1, 1)
        local d3 = OfferRouletteLogic.totalDuration(delays, 0.1, 3)
        expect(d1).toBeCloseTo(0.6, 0.001)
        expect(d3).toBeCloseTo(0.8, 0.001)
    end,
}
