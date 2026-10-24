--!strict
local NoiseLogic = require("../src/shared/util/NoiseLogic")

local CFG = {
    WALK_NOISE_PER_SEC = 1.5,
    SNEAK_NOISE_PER_SEC = 0.3,
    SURFACE_NOISE_MULT = { Crunchy = 3, Quiet = 0.4 },
    RESTLESS_AT = 40,
    EYE_OPEN_AT = 70,
    EYE_CLOSE_BELOW = 65,
    DECAY_PER_SEC = 4,
    DROUGHT_DECAY_PER_SEC = 1,
    WAKE_DROUGHT_SEC = 360,
}
local CARRY = { 1, 1.5, 2, 2.5, 3 }

return {
    ["stepRate: стоящий не шумит"] = function(expect)
        expect(
            NoiseLogic.stepRate({ moving = false, sneaking = false, carryWeight = 5 }, CFG, CARRY)
        ).toEqual(0)
    end,
    ["stepRate: шаг 1.5, крадётся 0.3"] = function(expect)
        expect(
            NoiseLogic.stepRate({ moving = true, sneaking = false, carryWeight = 0 }, CFG, CARRY)
        ).toBeCloseTo(1.5)
        expect(NoiseLogic.stepRate({ moving = true, sneaking = true, carryWeight = 0 }, CFG, CARRY)).toBeCloseTo(
            0.3
        )
    end,
    ["stepRate: вес 5 по монетам = 1.5 × 3 × 3"] = function(expect)
        expect(
            NoiseLogic.stepRate(
                { moving = true, sneaking = false, carryWeight = 5, surface = "Crunchy" },
                CFG,
                CARRY
            )
        ).toBeCloseTo(13.5)
    end,
    ["stepRate: мох и ботинки умножаются"] = function(expect)
        expect(NoiseLogic.stepRate({
            moving = true,
            sneaking = false,
            carryWeight = 2,
            surface = "Quiet",
            bootsMult = 0.5,
        }, CFG, CARRY)).toBeCloseTo(0.45)
    end,
    ["phaseFor: границы фаз"] = function(expect)
        expect(NoiseLogic.phaseFor(39.9, "Deep", CFG)).toEqual("Deep")
        expect(NoiseLogic.phaseFor(40, "Deep", CFG)).toEqual("Restless")
        expect(NoiseLogic.phaseFor(70, "Restless", CFG)).toEqual("EyeOpen")
    end,
    ["phaseFor: глаз закрывается только ниже 65"] = function(expect)
        expect(NoiseLogic.phaseFor(66, "EyeOpen", CFG)).toEqual("EyeOpen")
        expect(NoiseLogic.phaseFor(64, "EyeOpen", CFG)).toEqual("Restless")
        expect(NoiseLogic.phaseFor(66, "Restless", CFG)).toEqual("Restless")
    end,
    ["decayRate: засуха после 6 минут"] = function(expect)
        expect(NoiseLogic.decayRate(100, CFG)).toEqual(4)
        expect(NoiseLogic.decayRate(360, CFG)).toEqual(1)
    end,
    ["apply: зажат в 0..max"] = function(expect)
        expect(NoiseLogic.apply(98, 5, 100)).toEqual(100)
        expect(NoiseLogic.apply(1, -5, 100)).toEqual(0)
    end,
}
