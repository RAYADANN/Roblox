--!strict
local InventoryGridLogic = require("@shared/util/InventoryGridLogic")

return {
    ["2×2 fills width"] = function(expect)
        local w, h = InventoryGridLogic.cellScale(2, 2, 0.025, 0.022)
        expect(InventoryGridLogic.fillsRow(2, 0.025, 0.022, w)).toEqual(true)
        expect(w > 0.4).toEqual(true)
        expect(h > 0.4).toEqual(true)
    end,

    ["4×2 fills width"] = function(expect)
        local w, _h = InventoryGridLogic.cellScale(4, 2, 0.03, 0.025)
        expect(InventoryGridLogic.fillsRow(4, 0.03, 0.025, w)).toEqual(true)
        expect(w > 0.2).toEqual(true)
    end,

    ["row gap shrinks cell height"] = function(expect)
        local _w, hTight = InventoryGridLogic.cellScale(4, 2, 0.03, 0.025, 0.025)
        local _w2, hLoose = InventoryGridLogic.cellScale(4, 2, 0.03, 0.025, 0.055)
        expect(hLoose < hTight).toEqual(true)
    end,

    ["contentHeightScale: 8 items / 4 cols"] = function(expect)
        local cellH = 0.4
        local h = InventoryGridLogic.contentHeightScale(8, 4, cellH, 0.03, 0.055)
        -- pad*2 + 2*cellH + 1*rowGap
        expect(h).toBeCloseTo(0.03 * 2 + 0.4 * 2 + 0.055, 5)
    end,

    ["contentHeightScale: empty"] = function(expect)
        expect(InventoryGridLogic.contentHeightScale(0, 4, 0.4, 0.03, 0.055)).toBeCloseTo(0.06, 5)
    end,

    ["canvasHeightPx: content + scale pads"] = function(expect)
        expect(InventoryGridLogic.canvasHeightPx(400, 500, 0.03)).toBeCloseTo(430, 5)
    end,

    ["cellMetricsPx from viewport"] = function(expect)
        local m = InventoryGridLogic.cellMetricsPx(1000, 500, 0.2, 0.4, 0.03, 0.025, 0.055)
        expect(m.cellW).toBeCloseTo(200, 5)
        expect(m.cellH).toBeCloseTo(200, 5)
        expect(m.padX).toBeCloseTo(30, 5)
        expect(m.padY).toBeCloseTo(15, 5)
        expect(m.gapX).toBeCloseTo(25, 5)
        expect(m.gapY).toBeCloseTo(27.5, 5)
    end,

    ["designPxFromAbsolute undoes UIScale"] = function(expect)
        local x, y = InventoryGridLogic.designPxFromAbsolute(480, 270, 0.25)
        expect(x).toBeCloseTo(1920, 5)
        expect(y).toBeCloseTo(1080, 5)
    end,
}
