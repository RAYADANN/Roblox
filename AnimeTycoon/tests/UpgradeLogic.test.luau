return {
    ["cost level 0 cash"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.cost("cash", 0)).toEqual(300)
        local later = UpgradeLogic.cost("cash", 8) or 0
        expect(later > 300).toBeTruthy()
        local luck = UpgradeLogic.cost("luck", 20) or 0
        local cashLate = UpgradeLogic.cost("cash", 20) or 0
        expect(luck > 0).toBeTruthy()
        expect(luck < cashLate).toBeTruthy()
    end,
    ["rejects unknown upgrade"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.cost("unknown", 0)).toBe(nil)
    end,
    ["max level detection"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.isMaxLevel("cash", 20)).toBe(true)
        expect(UpgradeLogic.isMaxLevel("cash", 19)).toBe(false)
    end,
    ["status text cash"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.statusText("cash", 20)).toEqual("Current: +200%")
    end,
    ["ordered is seven items"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        local rows = UpgradeLogic.ordered()
        expect(#rows).toEqual(7)
        expect(rows[1].id).toEqual("base")
        expect(rows[2].id).toEqual("pad")
        expect(rows[3].id).toEqual("padTier")
        expect(rows[7].id).toEqual("speed")
    end,
    ["unlockedSlots starts at 10"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.unlockedSlots({})).toEqual(10)
        expect(UpgradeLogic.unlockedSlots({ base = 1 })).toEqual(11)
        expect(UpgradeLogic.unlockedSlots({ base = 20 })).toEqual(30)
    end,
    ["unlockedPads starts at 1"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.unlockedPads({})).toEqual(1)
        expect(UpgradeLogic.unlockedPads({ pad = 1 })).toEqual(2)
        expect(UpgradeLogic.unlockedPads({ pad = 4 })).toEqual(5)
        expect(UpgradeLogic.isPadUnlocked({}, 1)).toBe(true)
        expect(UpgradeLogic.isPadUnlocked({}, 2)).toBe(false)
        expect(UpgradeLogic.isPadUnlocked({ pad = 2 }, 3)).toBe(true)
        expect(UpgradeLogic.isMaxLevel("pad", 4)).toBe(true)
    end,
    ["floors unlock after 10 and 20"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.isFloorUnlocked({}, 1)).toBe(true)
        expect(UpgradeLogic.isFloorUnlocked({}, 2)).toBe(false)
        expect(UpgradeLogic.isFloorUnlocked({ base = 1 }, 2)).toBe(true)
        expect(UpgradeLogic.isFloorUnlocked({ base = 1 }, 3)).toBe(false)
        expect(UpgradeLogic.isFloorUnlocked({ base = 11 }, 3)).toBe(true)
    end,
    ["cash time speed formulas"] = function(expect)
        local UpgradeLogic = require("../src/shared/util/UpgradeLogic")
        expect(UpgradeLogic.cashMultiplier({ cash = 2 })).toBeCloseTo(1.2, 5)
        expect(UpgradeLogic.unpackTimeMultiplier({ time = 10 })).toBeCloseTo(0.9, 5)
        expect(UpgradeLogic.walkSpeed({ speed = 1 })).toBeCloseTo(16.5, 5)
        expect(UpgradeLogic.luckBias({ luck = 3 })).toBeCloseTo(0.45, 5)
        expect(UpgradeLogic.luckBias({ padTier = 2 })).toBeCloseTo(0.4, 5)
        expect(UpgradeLogic.luckBias({ luck = 1, padTier = 1 })).toBeCloseTo(0.35, 5)
        expect(UpgradeLogic.padTierTemplateName({})).toEqual(nil)
        expect(UpgradeLogic.padTierTemplateName({ padTier = 1 })).toEqual("Stand2LVL")
        expect(UpgradeLogic.padTierTemplateName({ padTier = 3 })).toEqual("Stand4LVL")
    end,
}
