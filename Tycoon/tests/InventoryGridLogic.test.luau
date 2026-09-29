--!strict
local InventoryGridLogic = require("../src/shared/util/InventoryGridLogic")

return {
    ["cellScale: 4-col fills row"] = function(expect)
        local w, _h = InventoryGridLogic.cellScale(4, 2, 0.03, 0.025)
        expect(InventoryGridLogic.fillsRow(4, 0.03, 0.025, w)).toEqual(true)
    end,
    ["designPxFromAbsolute divides UIScale"] = function(expect)
        local x, y = InventoryGridLogic.designPxFromAbsolute(480, 270, 0.25)
        expect(x).toBeCloseTo(1920)
        expect(y).toBeCloseTo(1080)
    end,
    ["cellMetricsPx uses design-local frame size"] = function(expect)
        local m = InventoryGridLogic.cellMetricsPx(1000, 500, 0.2, 0.4, 0.03, 0.025, 0.055)
        expect(m.cellW).toBeCloseTo(200)
        expect(m.cellH).toBeCloseTo(200)
        expect(m.padX).toBeCloseTo(30)
        expect(m.gapY).toBeCloseTo(27.5)
    end,
}
