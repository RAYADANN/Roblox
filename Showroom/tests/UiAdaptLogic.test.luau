--!strict
local InventoryGridLogic = require("../src/shared/util/InventoryGridLogic")
local UiAdaptLogic = require("../src/shared/util/UiAdaptLogic")

return {
    ["cellScale fills 4 cols"] = function(expect)
        local w, h = InventoryGridLogic.cellScale(4, 2, 0.02, 0.018, 0.04)
        expect(w > 0).toEqual(true)
        expect(h > 0).toEqual(true)
        local total = 2 * 0.02 + 4 * w + 3 * 0.018
        expect(math.abs(total - 1) < 1e-6).toEqual(true)
    end,

    ["fitScale shrinks to host"] = function(expect)
        local scale = UiAdaptLogic.fitScale({ X = 960, Y = 540 }, {
            reference = { X = 1920, Y = 1080 },
            minScale = 0.3,
            maxScale = 1.2,
            fit = true,
            mobileBoost = 1,
            mobileBelow = 900,
        })
        expect(scale).toEqual(0.5)
    end,
}
