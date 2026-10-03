--!strict
-- Pure poses for Roblox-native text FX lab (Hoarcekat). No Instances.

export type Pose = {
    -- UIGradient
    offsetX: number?,
    offsetY: number?,
    rotation: number?,
    -- UIScale
    scale: number?,
    -- TextLabel
    transparency: number?,
    -- UIStroke
    strokeThickness: number?,
    -- solid TextColor via HSV (hue 0..1); sat/val fixed in cell
    hue: number?,
    -- Position bob in scale units (applied as pos offset)
    bobY: number?,
    -- Dual solid flash: 0 = color A, 1 = color B
    flash: number?,
}

local TextFxLogic = {}

local function fract(x: number): number
    return x - math.floor(x)
end

--- Linear 0→1 loop.
local function saw(t: number, period: number): number
    return fract(t / period)
end

--- Hard ping-pong 0→1→0.
local function pingPong(t: number, period: number): number
    local c = saw(t, period) * 2
    if c > 1 then
        return 2 - c
    end
    return c
end

--- Stepped 0..steps-1, then normalized to -1..1 for offset.
local function steppedOffset(t: number, period: number, steps: number): number
    local s = math.max(2, math.floor(steps))
    local idx = math.floor(saw(t, period) * s)
    if idx >= s then
        idx = s - 1
    end
    return (idx / (s - 1)) * 2 - 1
end

--- Quad ease out 0→1.
local function easeOutQuad(u: number): number
    local x = 1 - math.clamp(u, 0, 1)
    return 1 - x * x
end

--[[
  Variants (Roblox-feeling, not AE shimmer):
  1 HardSweep   — linear sheen offset (Pet Sim style)
  2 StripeBand  — same sweep, cell uses narrow bright ColorSequence
  3 ScaleBounce — UIScale pulse like reward pop
  4 FloatBob    — Y bob (billboard / float text)
  5 Blink       — hard transparency blink
  6 StrokeThrob — stroke thickness pulse
  7 HueCycle    — HSV hue spin (rainbow limited)
  8 PopBurst    — occasional scale overshoot
  9 SnapSheen   — stepped offset (chunky, not sine)
 10 DualFlash   — alternate two solid colors
]]
function TextFxLogic.pose(variant: number, t: number): Pose
    if variant == 1 or variant == 2 then
        local u = saw(t, 1.4)
        return { offsetX = u * 2 - 1, offsetY = 0, rotation = 0 }
    end
    if variant == 3 then
        local u = pingPong(t, 1.1)
        local s = 1 + easeOutQuad(u) * 0.12
        return { scale = s }
    end
    if variant == 4 then
        return { bobY = math.sin(t * 3.2) * 0.04 }
    end
    if variant == 5 then
        local on = saw(t, 0.7) < 0.55
        return { transparency = if on then 0 else 0.55 }
    end
    if variant == 6 then
        local u = pingPong(t, 0.9)
        return { strokeThickness = 2 + u * 2.5 }
    end
    if variant == 7 then
        return { hue = fract(t * 0.22) }
    end
    if variant == 8 then
        local cycle = t % 2.4
        if cycle < 0.35 then
            local u = cycle / 0.35
            -- overshoot then settle
            local bump = if u < 0.45
                then easeOutQuad(u / 0.45) * 0.28
                else (1 - easeOutQuad((u - 0.45) / 0.55)) * 0.28
            return { scale = 1 + bump }
        end
        return { scale = 1 }
    end
    if variant == 9 then
        return { offsetX = steppedOffset(t, 1.5, 6), offsetY = 0, rotation = 0 }
    end
    if variant == 10 then
        local on = saw(t, 0.55) < 0.5
        return { flash = if on then 0 else 1 }
    end
    return {}
end

function TextFxLogic.labels(): { [number]: string }
    return {
        [1] = "1 HardSweep",
        [2] = "2 StripeBand",
        [3] = "3 ScaleBounce",
        [4] = "4 FloatBob",
        [5] = "5 Blink",
        [6] = "6 StrokeThrob",
        [7] = "7 HueCycle",
        [8] = "8 PopBurst",
        [9] = "9 SnapSheen",
        [10] = "10 DualFlash",
    }
end

return TextFxLogic
