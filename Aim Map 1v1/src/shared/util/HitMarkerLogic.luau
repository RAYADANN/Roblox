--!strict
-- Valorant-style crosshair hit confirm: kind → color / timing (pure).

export type HitMarkerKind = "body" | "head" | "kill"

export type Rgb = { r: number, g: number, b: number }

local HitMarkerLogic = {}

function HitMarkerLogic.kind(headshot: boolean, killed: boolean): HitMarkerKind
    if killed then
        return "kill"
    end
    if headshot then
        return "head"
    end
    return "body"
end

--- 0–255 channels for the hitmarker ticks (white–sky HUD chrome).
function HitMarkerLogic.rgb(kind: HitMarkerKind): Rgb
    if kind == "kill" then
        -- Primary blue — strongest confirm
        return { r = 82, g = 126, b = 255 }
    end
    if kind == "head" then
        -- Sky blue
        return { r = 115, g = 199, b = 255 }
    end
    return { r = 255, g = 255, b = 255 }
end

--- Seconds until fade begins (hold at full opacity).
function HitMarkerLogic.holdSec(kind: HitMarkerKind): number
    if kind == "kill" then
        return 0.14
    end
    if kind == "head" then
        return 0.1
    end
    return 0.08
end

--- Peak outward expand scale (1 = resting gap).
function HitMarkerLogic.expandPeak(kind: HitMarkerKind): number
    if kind == "kill" then
        return 1.35
    end
    if kind == "head" then
        return 1.28
    end
    return 1.2
end

return HitMarkerLogic
