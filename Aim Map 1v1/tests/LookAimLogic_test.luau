local LookAimLogic = require("@shared/util/LookAimLogic")

return {
    ["spinePitch: scaled"] = function(expect)
        expect(LookAimLogic.spinePitch(0.4, 1)).toBeCloseTo(0.4, 1e-6)
        expect(LookAimLogic.spinePitch(0.4, 0.5)).toBeCloseTo(0.2, 1e-6)
    end,
    ["spinePitch: clamps scale and rejects nan"] = function(expect)
        expect(LookAimLogic.spinePitch(1, 2)).toBeCloseTo(1, 1e-6)
        expect(LookAimLogic.spinePitch(0 / 0, 1)).toEqual(0)
    end,
}
