--!strict
-- Pure FTUE spotlight math: viewport → hole + off-screen arrow.

export type Focus = {
    x: number,
    y: number,
    onScreen: boolean,
    arrowDeg: number,
}

local TutorialFocusLogic = {}

TutorialFocusLogic.EDGE_MARGIN = 0.12
TutorialFocusLogic.POS_EPS = 0.004
TutorialFocusLogic.DEG_EPS = 2

function TutorialFocusLogic.arrowDeg(dx: number, dy: number): number
    if dx * dx + dy * dy < 1e-12 then
        return 0
    end
    -- ▲ at Rotation 0 points up (0, -1). Roblox Rotation is clockwise.
    return math.deg(math.atan2(dx, -dy))
end

function TutorialFocusLogic.clampToEdge(nx: number, ny: number, margin: number): (number, number)
    local dx = nx - 0.5
    local dy = ny - 0.5
    if math.abs(dx) < 1e-8 and math.abs(dy) < 1e-8 then
        return 0.5, margin
    end
    local limX = 0.5 - margin
    local limY = 0.5 - margin
    local tx = if math.abs(dx) < 1e-8 then math.huge else limX / math.abs(dx)
    local ty = if math.abs(dy) < 1e-8 then math.huge else limY / math.abs(dy)
    local t = math.min(tx, ty)
    return 0.5 + dx * t, 0.5 + dy * t
end

function TutorialFocusLogic.heading(fromX: number, fromY: number, toX: number, toY: number): number
    return TutorialFocusLogic.arrowDeg(toX - fromX, toY - fromY)
end

function TutorialFocusLogic.arrowOffset(arrowDeg: number, dist: number): (number, number)
    local rad = math.rad(arrowDeg)
    return math.sin(rad) * dist, -math.cos(rad) * dist
end

-- Sit on the focus-rect border along `outwardDeg` (from center). Tip faces `tipDeg`.
-- Always outside the hole interior.
function TutorialFocusLogic.arrowOutsideFrame(
    cx: number,
    cy: number,
    halfW: number,
    halfH: number,
    outwardDeg: number,
    tipDeg: number,
    marginOut: number
): (number, number, number)
    local rad = math.rad(outwardDeg)
    local dx = math.sin(rad)
    local dy = -math.cos(rad)
    local tx = if math.abs(dx) < 1e-8 then math.huge else halfW / math.abs(dx)
    local ty = if math.abs(dy) < 1e-8 then math.huge else halfH / math.abs(dy)
    local t = math.min(tx, ty) + marginOut
    return cx + dx * t, cy + dy * t, tipDeg
end

function TutorialFocusLogic.expAlpha(dt: number, speed: number): number
    if dt <= 0 or speed <= 0 then
        return 1
    end
    return 1 - math.exp(-speed * dt)
end

-- Shortest-path angle lerp (degrees).
function TutorialFocusLogic.lerpAngle(fromDeg: number, toDeg: number, alpha: number): number
    local d = toDeg - fromDeg
    while d > 180 do
        d -= 360
    end
    while d < -180 do
        d += 360
    end
    return fromDeg + d * alpha
end

function TutorialFocusLogic.lerp(a: number, b: number, alpha: number): number
    return a + (b - a) * alpha
end

function TutorialFocusLogic.fromViewport(
    px: number,
    py: number,
    depth: number,
    viewX: number,
    viewY: number,
    margin: number
): Focus
    if viewX <= 0 or viewY <= 0 then
        return { x = 0.5, y = 0.42, onScreen = false, arrowDeg = 0 }
    end
    local sx = px
    local sy = py
    if depth < 0 then
        sx = viewX - sx
        sy = viewY - sy
    end
    local nx = sx / viewX
    local ny = sy / viewY
    local pad = margin
    local onScreen = depth > 0 and nx >= pad and nx <= 1 - pad and ny >= pad and ny <= 1 - pad
    local deg = TutorialFocusLogic.arrowDeg(nx - 0.5, ny - 0.5)
    if onScreen then
        return { x = nx, y = ny, onScreen = true, arrowDeg = 180 }
    end
    local ex, ey = TutorialFocusLogic.clampToEdge(nx, ny, pad)
    return { x = ex, y = ey, onScreen = false, arrowDeg = deg }
end

function TutorialFocusLogic.changed(a: Focus, b: Focus): boolean
    if a.onScreen ~= b.onScreen then
        return true
    end
    if math.abs(a.x - b.x) > TutorialFocusLogic.POS_EPS then
        return true
    end
    if math.abs(a.y - b.y) > TutorialFocusLogic.POS_EPS then
        return true
    end
    local d = a.arrowDeg - b.arrowDeg
    while d > 180 do
        d -= 360
    end
    while d < -180 do
        d += 360
    end
    return math.abs(d) > TutorialFocusLogic.DEG_EPS
end

return TutorialFocusLogic
