--!strict
-- Pure: inventory UIGrid cell fractions from pad/gap/cols/rows.

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

function InventoryGridLogic.fillsRow(
    columns: number,
    padScale: number,
    colGapScale: number,
    cellW: number
): boolean
    local cols = math.max(1, columns)
    local total = 2 * padScale + cols * cellW + (cols - 1) * colGapScale
    return math.abs(total - 1) < 1e-6
end

--- Canvas height as a Scale of the ScrollingFrame (includes outer pad + row gaps).
function InventoryGridLogic.contentHeightScale(
    itemCount: number,
    columns: number,
    cellH: number,
    padScale: number,
    rowGapScale: number
): number
    local cols = math.max(1, columns)
    local count = math.max(0, itemCount)
    local rows = if count == 0 then 0 else math.ceil(count / cols)
    if rows == 0 then
        return 2 * padScale
    end
    return 2 * padScale + rows * cellH + (rows - 1) * rowGapScale
end

--- Pixel canvas height from UIGridLayout.AbsoluteContentSize + UIPadding (Scale pads).
function InventoryGridLogic.canvasHeightPx(
    contentAbsoluteY: number,
    frameAbsoluteY: number,
    padScale: number
): number
    local pad = math.clamp(padScale, 0, 0.4)
    local frameY = math.max(0, frameAbsoluteY)
    local contentY = math.max(0, contentAbsoluteY)
    return contentY + 2 * frameY * pad
end

--- Convert AbsoluteSize (post-UIScale) back to DesignRoot local px.
function InventoryGridLogic.designPxFromAbsolute(
    absoluteX: number,
    absoluteY: number,
    uiScale: number
): (number, number)
    local s = math.max(uiScale, 1e-6)
    return math.max(0, absoluteX) / s, math.max(0, absoluteY) / s
end

--- Pixel metrics for UIGridLayout / UIPadding from viewport AbsoluteSize.
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
