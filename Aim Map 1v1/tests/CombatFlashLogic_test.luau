local CombatFlashLogic = require("@shared/util/CombatFlashLogic")

return {
    ["peakOpacity: damage stronger than kill"] = function(expect)
        local dmg = CombatFlashLogic.peakOpacity("damage", false)
        local kill = CombatFlashLogic.peakOpacity("kill", false)
        expect(dmg > kill).toEqual(true)
        expect(dmg <= 1).toEqual(true)
    end,
    ["peakOpacity: reduceMotion scales down"] = function(expect)
        local full = CombatFlashLogic.peakOpacity("damage", false)
        local reduced = CombatFlashLogic.peakOpacity("damage", true)
        expect(reduced < full).toEqual(true)
        expect(reduced > 0).toEqual(true)
    end,
    ["backgroundTransparency: 0 opacity is invisible"] = function(expect)
        expect(CombatFlashLogic.backgroundTransparency(0)).toBeCloseTo(1, 1e-6)
        expect(CombatFlashLogic.backgroundTransparency(1)).toBeCloseTo(0, 1e-6)
        expect(CombatFlashLogic.backgroundTransparency(0.5)).toBeCloseTo(0.5, 1e-6)
    end,
    ["holdSec: reduceMotion is shorter"] = function(expect)
        expect(CombatFlashLogic.holdSec(true) < CombatFlashLogic.holdSec(false)).toEqual(true)
    end,
}
