--!strict
local ExhibitLogic = require("../src/shared/util/ExhibitLogic")

return {
    ["evolveDuration: rare slower than common"] = function(expect)
        expect(ExhibitLogic.evolveDuration("rare") > ExhibitLogic.evolveDuration("common")).toBeTruthy()
        expect(ExhibitLogic.evolveDuration("legendary") > ExhibitLogic.evolveDuration("epic")).toBeTruthy()
    end,
    ["progress: clamps 0..1"] = function(expect)
        local half = ExhibitLogic.evolveDuration("common") * 0.5
        expect(ExhibitLogic.progress(0, "common")).toEqual(0)
        expect(ExhibitLogic.progress(half, "common")).toBeCloseTo(0.5, 1e-6)
        expect(ExhibitLogic.progress(9999, "common")).toEqual(1)
    end,
    ["incomeAt: grows with progress"] = function(expect)
        local a = ExhibitLogic.incomeAt("common", 0, 0)
        local b = ExhibitLogic.incomeAt("common", 1, 0)
        expect(b > a).toBeTruthy()
        expect(a).toEqual(5)
    end,
    ["rollNpcCount: within rarity range"] = function(expect)
        local n = ExhibitLogic.rollNpcCount("rare", 0)
        expect(n >= 6).toBeTruthy()
        expect(n <= 10).toBeTruthy()
        local hi = ExhibitLogic.rollNpcCount("legendary", 0.999)
        expect(hi >= 10).toBeTruthy()
        expect(hi <= 18).toBeTruthy()
    end,
    ["rollCrowd: avoid yields zero"] = function(expect)
        local n, shunned = ExhibitLogic.rollCrowd("common", 0, 0.5)
        expect(shunned).toBeTruthy()
        expect(n).toEqual(0)
    end,
    ["npcTarget: ramps from rolled base"] = function(expect)
        expect(ExhibitLogic.npcTargetCount(8, 0, false)).toEqual(0)
        expect(ExhibitLogic.npcTargetCount(8, 0.2, false)).toEqual(8)
        expect(ExhibitLogic.npcTargetCount(8, 1, true)).toEqual(7)
        expect(ExhibitLogic.npcTargetCount(0, 1, false)).toEqual(0)
    end,
    ["pickAnim: spin only for MVP"] = function(expect)
        expect(ExhibitLogic.pickAnim(0)).toEqual("spin")
        expect(ExhibitLogic.pickAnim(0.99)).toEqual("spin")
        local ids = ExhibitLogic.animIds()
        expect(#ids).toEqual(1)
        expect(ids[1]).toEqual("spin")
    end,
    ["highlightTransparency: more transparent at end"] = function(expect)
        local a = ExhibitLogic.highlightTransparency(0, false)
        local b = ExhibitLogic.highlightTransparency(1, false)
        expect(b > a).toBeTruthy()
    end,
    ["sellPrice: mutated worth more"] = function(expect)
        local base = ExhibitLogic.sellPrice("rare", 1, false, 14)
        local mut = ExhibitLogic.sellPrice("rare", 1, true, 14, 1)
        expect(mut > base).toBeTruthy()
    end,
    ["buyPrice: size and mutations raise cost"] = function(expect)
        local med = ExhibitLogic.buyPrice("common", "medium", 0)
        local giant = ExhibitLogic.buyPrice("common", "giant", 0)
        local mut = ExhibitLogic.buyPrice("common", "medium", 1)
        expect(med).toEqual(20)
        expect(giant > med).toBeTruthy()
        expect(mut > med).toBeTruthy()
    end,
    ["rollSize: weight bands"] = function(expect)
        expect(ExhibitLogic.rollSize(0)).toEqual("small")
        expect(ExhibitLogic.rollSize(0.49)).toEqual("small")
        expect(ExhibitLogic.rollSize(0.50)).toEqual("medium")
        expect(ExhibitLogic.rollSize(0.79)).toEqual("medium")
        expect(ExhibitLogic.rollSize(0.80)).toEqual("large")
        expect(ExhibitLogic.rollSize(0.97)).toEqual("large")
        expect(ExhibitLogic.rollSize(0.98)).toEqual("giant")
    end,
    ["sizeMult: ordered Small < Medium < Large < Giant"] = function(expect)
        expect(ExhibitLogic.sizeMult("small") < ExhibitLogic.sizeMult("medium")).toBeTruthy()
        expect(ExhibitLogic.sizeMult("medium") < ExhibitLogic.sizeMult("large")).toBeTruthy()
        expect(ExhibitLogic.sizeMult("large") < ExhibitLogic.sizeMult("giant")).toBeTruthy()
    end,
    ["visualScale: size multiplies growth"] = function(expect)
        local med = ExhibitLogic.visualScale(0, false, "medium")
        local large = ExhibitLogic.visualScale(0, false, "large")
        local giantSize = ExhibitLogic.visualScale(0, false, "giant")
        expect(med).toEqual(1)
        expect(large).toEqual(1.5)
        expect(giantSize).toEqual(3) -- 2× Large
        expect(
            ExhibitLogic.visualScale(1, false, "small")
                < ExhibitLogic.visualScale(1, false, "large")
        ).toBeTruthy()
    end,
    ["visualScale: Giant mutation is 2× Large, scale only"] = function(expect)
        local large = ExhibitLogic.visualScale(0, false, "medium")
        local withGiant = ExhibitLogic.visualScale(0, true, "medium", { "giant" })
        expect(large).toEqual(1)
        expect(withGiant).toEqual(3)
        expect(ExhibitLogic.hasGiantMutation({ "spark", "giant" })).toBeTruthy()
        expect(ExhibitLogic.hasGiantMutation({ "spark" })).toBeFalsy()
    end,
    ["hatch: egg shrinks then pet grows"] = function(expect)
        local hatch = ExhibitLogic.hatchProgress()
        expect(hatch).toBeCloseTo(0.52, 1e-6)
        expect(ExhibitLogic.hatchEggScale(0, false, false, "medium")).toEqual(1)
        expect(ExhibitLogic.hatchEggScale(hatch, false, false, "medium")).toEqual(0)
        expect(ExhibitLogic.hatchEggScale(1, false, false, "medium")).toEqual(0)
        expect(ExhibitLogic.hatchEggScale(0.5, true, false, "medium")).toEqual(0)
        expect(ExhibitLogic.hatchPetScale(0, false, false, "medium")).toEqual(0)
        expect(ExhibitLogic.hatchPetScale(hatch, false, false, "medium")).toEqual(0)
        local full = ExhibitLogic.visualScale(1, false, "medium")
        expect(ExhibitLogic.hatchPetScale(1, false, false, "medium")).toEqual(full)
        expect(ExhibitLogic.hatchPetScale(0.5, true, false, "medium")).toEqual(full)
        local mid = hatch + (1 - hatch) * 0.5
        expect(ExhibitLogic.hatchPetScale(mid, false, false, "medium")).toBeCloseTo(
            full * 0.5,
            1e-6
        )
    end,
    ["sizeLabel: title case"] = function(expect)
        expect(ExhibitLogic.sizeLabel("large")).toEqual("Large")
        expect(ExhibitLogic.sizeLabel(nil)).toEqual("Medium")
    end,
    ["isValidSlot"] = function(expect)
        expect(ExhibitLogic.isValidSlot(1)).toBeTruthy()
        expect(ExhibitLogic.isValidSlot(6)).toBeTruthy()
        expect(ExhibitLogic.isValidSlot(0)).toBeFalsy()
        expect(ExhibitLogic.isValidSlot(7)).toBeFalsy()
    end,
}
