local ViewModelLogic = require("@shared/util/ViewModelLogic")

return {
    ["shouldStripPart: legs and head only"] = function(expect)
        expect(ViewModelLogic.shouldStripPart("Head")).toEqual(true)
        expect(ViewModelLogic.shouldStripPart("LeftUpperLeg")).toEqual(true)
        expect(ViewModelLogic.shouldStripPart("RightHand")).toEqual(false)
        expect(ViewModelLogic.shouldStripPart("UpperTorso")).toEqual(false)
        expect(ViewModelLogic.shouldStripPart("HumanoidRootPart")).toEqual(false)
    end,
    ["shouldHideMesh: torso kept but hidden"] = function(expect)
        expect(ViewModelLogic.shouldHideMesh("UpperTorso")).toEqual(true)
        expect(ViewModelLogic.shouldHideMesh("LowerTorso")).toEqual(true)
        expect(ViewModelLogic.shouldHideMesh("HumanoidRootPart")).toEqual(true)
        expect(ViewModelLogic.shouldHideMesh("RightHand")).toEqual(false)
    end,
    ["eyeHeight: uses head minus root"] = function(expect)
        expect(ViewModelLogic.eyeHeight(4.41, 2.26, 2.1)).toBeCloseTo(2.15, 1e-6)
    end,
    ["eyeHeight: falls back on garbage"] = function(expect)
        expect(ViewModelLogic.eyeHeight(0 / 0, 0, 2.1)).toBeCloseTo(2.1, 1e-6)
        expect(ViewModelLogic.eyeHeight(1, 1, 2.1)).toBeCloseTo(2.1, 1e-6)
    end,
    ["localOffset: forward maps to -Z"] = function(expect)
        local x, y, z = ViewModelLogic.localOffset(0.1, -1.2, 0.8)
        expect(x).toBeCloseTo(0.1, 1e-6)
        expect(y).toBeCloseTo(-1.2, 1e-6)
        expect(z).toBeCloseTo(-0.8, 1e-6)
    end,
    ["cameraLocalOffset: HRP sits below the lens"] = function(expect)
        local x, y, z = ViewModelLogic.cameraLocalOffset(2.15, 0, 0, 0)
        expect(x).toBeCloseTo(0, 1e-6)
        expect(y).toBeCloseTo(-2.15, 1e-6)
        expect(z).toBeCloseTo(0, 1e-6)
    end,
    ["rigPosition: applies offset along camera basis"] = function(expect)
        -- Camera at origin looking -Z, standard basis.
        local x, y, z = ViewModelLogic.rigPosition(10, 5, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1, 0, -1, 1)
        expect(x).toBeCloseTo(10, 1e-5)
        expect(y).toBeCloseTo(4, 1e-5)
        expect(z).toBeCloseTo(-1, 1e-5)
    end,
}
