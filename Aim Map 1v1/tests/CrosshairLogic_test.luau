local CrosshairDatabase = require("@shared/data/CrosshairDatabase")
local CrosshairLogic = require("@shared/util/CrosshairLogic")

return {
    ["default is classic"] = function(expect)
        expect(CrosshairLogic.default()).toEqual("classic")
        expect(CrosshairDatabase.isValid("classic")).toEqual(true)
    end,

    ["resolve falls back"] = function(expect)
        expect(CrosshairLogic.resolve(nil)).toEqual("classic")
        expect(CrosshairLogic.resolve("nope")).toEqual("classic")
        expect(CrosshairLogic.resolve("dot")).toEqual("dot")
    end,

    ["list has several presets"] = function(expect)
        expect(#CrosshairDatabase.list() >= 6).toEqual(true)
    end,
}
