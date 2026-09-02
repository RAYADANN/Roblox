local HitMarkerLogic = require("@shared/util/HitMarkerLogic")

return {
    ["kind: body / head / kill priority"] = function(expect)
        expect(HitMarkerLogic.kind(false, false)).toEqual("body")
        expect(HitMarkerLogic.kind(true, false)).toEqual("head")
        expect(HitMarkerLogic.kind(false, true)).toEqual("kill")
        expect(HitMarkerLogic.kind(true, true)).toEqual("kill")
    end,
    ["rgb: white–sky body / head sky / kill primary"] = function(expect)
        local body = HitMarkerLogic.rgb("body")
        expect(body.r).toEqual(255)
        expect(body.g).toEqual(255)
        expect(body.b).toEqual(255)
        local head = HitMarkerLogic.rgb("head")
        expect(head.r).toEqual(115)
        expect(head.g).toEqual(199)
        expect(head.b).toEqual(255)
        local kill = HitMarkerLogic.rgb("kill")
        expect(kill.r).toEqual(82)
        expect(kill.g).toEqual(126)
        expect(kill.b).toEqual(255)
    end,
    ["expandPeak: kill > head > body"] = function(expect)
        expect(HitMarkerLogic.expandPeak("kill") > HitMarkerLogic.expandPeak("head")).toEqual(true)
        expect(HitMarkerLogic.expandPeak("head") > HitMarkerLogic.expandPeak("body")).toEqual(true)
    end,
}
