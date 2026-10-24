--!strict
local CarryLogic = require("../src/shared/util/CarryLogic")

local ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

return {
    ["canLift: сила не меньше Need"] = function(expect)
        expect(CarryLogic.canLift(100, 50)).toBeTruthy()
        expect(CarryLogic.canLift(100, 100)).toBeTruthy()
        expect(CarryLogic.canLift(100, 2000)).toBeFalsy()
    end,
    ["speedMult: ступени по отношению Strength / Need"] = function(expect)
        local steps =
            { { ratio = 2, mult = 0.6 }, { ratio = 5, mult = 0.75 }, { ratio = 10, mult = 0.9 } }
        expect(CarryLogic.speedMult(100, 100, steps)).toEqual(0.6)
        expect(CarryLogic.speedMult(200, 100, steps)).toEqual(0.75)
        expect(CarryLogic.speedMult(500, 100, steps)).toEqual(0.9)
        expect(CarryLogic.speedMult(1000, 100, steps)).toEqual(1)
    end,
    ["launchVelocity: высота дуги = height"] = function(expect)
        local _, vy, _ = CarryLogic.launchVelocity(1, 0, 140, 60, 196.2)
        expect(vy * vy / (2 * 196.2)).toBeCloseTo(60, 1e-4)
    end,
    ["launchVelocity: дальность = dist"] = function(expect)
        local vx, vy, vz = CarryLogic.launchVelocity(3, 4, 140, 60, 196.2)
        local flight = 2 * vy / 196.2
        expect(math.sqrt(vx * vx + vz * vz) * flight).toBeCloseTo(140, 1e-4)
    end,
    ["rollRarity: границы шансов"] = function(expect)
        local chances = { Common = 80, Uncommon = 20 }
        expect(CarryLogic.rollRarity(chances, ORDER, 0)).toEqual("Common")
        expect(CarryLogic.rollRarity(chances, ORDER, 79.99)).toEqual("Common")
        expect(CarryLogic.rollRarity(chances, ORDER, 80)).toEqual("Uncommon")
        expect(CarryLogic.rollRarity(chances, ORDER, 99.99)).toEqual("Uncommon")
    end,
    ["chancesSum: кольцо Inner = 100"] = function(expect)
        expect(CarryLogic.chancesSum({ Rare = 40, Epic = 42, Legendary = 16, Mythic = 2 })).toEqual(
            100
        )
    end,
}
