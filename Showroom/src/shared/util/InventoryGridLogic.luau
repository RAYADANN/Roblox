--!strict
-- Pure: UIGrid cell fractions from pad/gap/cols/rows (Tycoon / Aim Map inventory).

local InventoryGridLogic = {}

function InventoryGridLogic.cellScale(
    columns: number,
    rowsVisible: number,
    padScale: number,
    colGapScale: number,
    rowGapScale: number?
): (number, number)
    local cols = math.max(1, columns)
    local rows = math.max(1, rowsVisible)
    local pad = math.clamp(padScale, 0, 0.4)
    local colGap = math.clamp(colGapScale, 0, 0.4)
    local rowGap = math.clamp(if rowGapScale ~= nil then rowGapScale else colGapScale, 0, 0.4)
    local cellW = (1 - 2 * pad - (cols - 1) * colGap) / cols
    local cellH = (1 - 2 * pad - (rows - 1) * rowGap) / rows
    return cellW, cellH
end

function InventoryGridLogic.designPxFromAbsolute(
    absoluteX: number,
    absoluteY: number,
    uiScale: number
): (number, number)
    local s = math.max(uiScale, 1e-6)
    return math.max(0, absoluteX) / s, math.max(0, absoluteY) / s
end

function InventoryGridLogic.cellMetricsPx(
    frameAbsoluteX: number,
    frameAbsoluteY: number,
    cellWScale: number,
    cellHScale: number,
    padScale: number,
    colGapScale: number,
    rowGapScale: number
): {
    cellW: number,
    cellH: number,
    padX: number,
    padY: number,
    gapX: number,
    gapY: number,
}
    local ax = math.max(0, frameAbsoluteX)
    local ay = math.max(0, frameAbsoluteY)
    local pad = math.clamp(padScale, 0, 0.4)
    return {
        cellW = ax * cellWScale,
        cellH = ay * cellHScale,
        padX = ax * pad,
        padY = ay * pad,
        gapX = ax * colGapScale,
        gapY = ay * rowGapScale,
    }
end

return InventoryGridLogic
