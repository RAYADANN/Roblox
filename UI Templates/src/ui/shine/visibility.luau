--!strict
-- Axis-aligned overlap: is `host` inside ScrollingFrame viewport (+ optional margin)?

export type Rect = {
    x: number,
    y: number,
    w: number,
    h: number,
}

local function intersects(a: Rect, b: Rect): boolean
    return a.x + a.w > b.x and a.x < b.x + b.w and a.y + a.h > b.y and a.y < b.y + b.h
end

local function guiRect(gui: GuiObject): Rect
    local pos = gui.AbsolutePosition
    local size = gui.AbsoluteSize
    return {
        x = pos.X,
        y = pos.Y,
        w = size.X,
        h = size.Y,
    }
end

local function isInScrollView(host: GuiObject, scroll: ScrollingFrame, marginPx: number?): boolean
    local margin = marginPx or 0
    local hostRect = guiRect(host)
    local view = guiRect(scroll)
    view.x -= margin
    view.y -= margin
    view.w += margin * 2
    view.h += margin * 2
    return intersects(hostRect, view)
end

return {
    intersects = intersects,
    guiRect = guiRect,
    isInScrollView = isInScrollView,
}
