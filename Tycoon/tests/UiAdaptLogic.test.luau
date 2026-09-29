--!strict
local UiAdaptLogic = require("../src/shared/util/UiAdaptLogic")

local REF = { X = 1920, Y = 1080 }
local FIT = {
    reference = REF,
    minScale = 0.3,
    maxScale = 1.2,
    fit = true,
    mobileBoost = 1,
    mobileBelow = 900,
}

return {
    ["phone landscape canvas fits"] = function(expect)
        local usable = { X = 831, Y = 348 }
        local scale = UiAdaptLogic.fitScale(usable, FIT)
        expect(UiAdaptLogic.canvasFits(usable, REF, scale)).toEqual(true)
    end,

    ["fit never exceeds even if minScale is higher"] = function(expect)
        local usable = { X = 400, Y = 200 }
        local config = table.clone(FIT)
        config.minScale = 0.9
        local scale = UiAdaptLogic.fitScale(usable, config)
        local fitScale = math.min(400 / 1920, 200 / 1080)
        expect(scale).toEqual(fitScale)
    end,

    ["desktop fit is 1 on reference"] = function(expect)
        local scale = UiAdaptLogic.fitScale({ X = 1920, Y = 1080 }, FIT)
        expect(scale).toEqual(1)
    end,
}
