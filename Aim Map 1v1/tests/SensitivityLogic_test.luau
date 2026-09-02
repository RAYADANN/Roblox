local SensitivityLogic = require("@shared/util/SensitivityLogic")

return {
    ["clamp keeps in range"] = function(expect)
        expect(SensitivityLogic.clamp(0)).toEqual(0.2)
        expect(SensitivityLogic.clamp(99)).toEqual(3)
        expect(SensitivityLogic.clamp(1.25)).toEqual(1.25)
    end,

    ["step rounds to 0.1"] = function(expect)
        expect(SensitivityLogic.step(1, 0.1)).toEqual(1.1)
        expect(SensitivityLogic.step(1, -0.1)).toEqual(0.9)
    end,

    ["isValid rejects out of range"] = function(expect)
        expect(SensitivityLogic.isValid(1)).toEqual(true)
        expect(SensitivityLogic.isValid(0.05)).toEqual(false)
    end,

    ["fromRatio / toRatio roundtrip"] = function(expect)
        expect(SensitivityLogic.fromRatio(0)).toEqual(0.2)
        expect(SensitivityLogic.fromRatio(1)).toEqual(3)
        expect(SensitivityLogic.toRatio(1)).toBeCloseTo((1 - 0.2) / (3 - 0.2), 1e-6)
    end,
}
