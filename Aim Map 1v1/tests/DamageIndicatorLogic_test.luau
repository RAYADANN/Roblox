local DamageIndicatorLogic = require("@shared/util/DamageIndicatorLogic")

return {
    ["relativeBearing: ahead is ~0"] = function(expect)
        local b = DamageIndicatorLogic.relativeBearing(0, 0, 0, 0, -10)
        expect(math.abs(b) < 0.05).toEqual(true)
    end,
    ["indicatorRotation: right is ~+90"] = function(expect)
        local deg = DamageIndicatorLogic.indicatorRotationDegrees(0, 0, 0, 10, 0)
        expect(deg).toBeCloseTo(90, 4)
    end,
    ["indicatorRotation: behind is ~±180"] = function(expect)
        local deg = DamageIndicatorLogic.indicatorRotationDegrees(0, 0, 0, 0, 10)
        expect(math.abs(math.abs(deg) - 180) < 4).toEqual(true)
    end,
    ["vignetteStrength scales with damage"] = function(expect)
        local body = DamageIndicatorLogic.vignetteStrength(34, 100)
        local head = DamageIndicatorLogic.vignetteStrength(100, 100)
        expect(body > 0.2).toEqual(true)
        expect(head > body).toEqual(true)
        expect(head <= 1).toEqual(true)
    end,
    ["normalizeAngle wraps"] = function(expect)
        expect(DamageIndicatorLogic.normalizeAngle(3 * math.pi)).toBeCloseTo(math.pi, 0.05)
    end,
}
