local SkinDatabase = require("@shared/data/SkinDatabase")

return {
    ["tracerRgb: default warm"] = function(expect)
        local rgb = SkinDatabase.tracerRgb("usp_default")
        expect(rgb.r).toEqual(255)
        expect(rgb.g).toEqual(236)
        expect(rgb.b).toEqual(170)
    end,
    ["tracerRgb: crimson is red-leaning"] = function(expect)
        local rgb = SkinDatabase.tracerRgb("usp_crimson")
        expect(rgb.r > rgb.g).toEqual(true)
        expect(rgb.r > rgb.b).toEqual(true)
    end,
    ["tracerRgb: unknown falls back to default"] = function(expect)
        local a = SkinDatabase.tracerRgb("nope")
        local b = SkinDatabase.tracerRgb("usp_default")
        expect(a.r).toEqual(b.r)
        expect(a.g).toEqual(b.g)
        expect(a.b).toEqual(b.b)
    end,
    ["resolveId / isValid"] = function(expect)
        expect(SkinDatabase.isValid("usp_neon")).toEqual(true)
        expect(SkinDatabase.resolveId("bad")).toEqual("usp_default")
    end,
}
