--!strict
-- Roblox-popular color sheens: linear sheen, white band, hue shift, solid rainbow,
-- dual flash, chrome — не AE sine/orbit. Pure (Lune). Hoarcekat → lock later.

export type Rgb = { r: number, g: number, b: number }
export type Key = { t: number, c: Rgb }
export type Offset = { x: number, y: number }

export type SheenPose = {
    offset: Offset,
    rotation: number,
    midTransparency: number?,
    --- Replace UIGradient.Color (recolor modes).
    keys: { Key }?,
    --- Solid TextColor3; hide/disable gradient when set.
    solid: Rgb?,
}

local ZERO: Offset = { x = 0, y = 0 }
local WHITE: Rgb = { r = 255, g = 255, b = 255 }

local function fract(x: number): number
    return x - math.floor(x)
end

local function saw(t: number, period: number): number
    return fract(t / math.max(period, 0.01))
end

local function pingPongLinear(t: number, period: number): number
    local u = saw(t, period) * 2
    if u > 1 then
        return 2 - u
    end
    return u
end

local function pauseSweep(t: number, period: number, holdFrac: number): number
    local u = saw(t, period)
    local hold = math.clamp(holdFrac, 0, 0.4)
    local move = 1 - hold * 2
    if u < hold then
        return 0
    end
    if u > 1 - hold then
        return 1
    end
    return (u - hold) / move
end

local function clampByte(n: number): number
    return math.clamp(math.floor(n + 0.5), 0, 255)
end

local function rgbToHsv(c: Rgb): (number, number, number)
    local r, g, b = c.r / 255, c.g / 255, c.b / 255
    local maxc = math.max(r, g, b)
    local minc = math.min(r, g, b)
    local d = maxc - minc
    local h = 0
    if d > 1e-6 then
        if maxc == r then
            h = ((g - b) / d) % 6
        elseif maxc == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h /= 6
        if h < 0 then
            h += 1
        end
    end
    local s = if maxc <= 1e-6 then 0 else d / maxc
    return h, s, maxc
end

local function hsvToRgb(h: number, s: number, v: number): Rgb
    local hh = fract(h) * 6
    local i = math.floor(hh)
    local f = hh - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    local r, g, b = v, t, p
    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end
    return { r = clampByte(r * 255), g = clampByte(g * 255), b = clampByte(b * 255) }
end

local function shiftKeys(keys: { Key }, hueDelta: number): { Key }
    local out: { Key } = {}
    for _, key in keys do
        local h, s, v = rgbToHsv(key.c)
        table.insert(out, {
            t = key.t,
            c = hsvToRgb(h + hueDelta, s, v),
        })
    end
    return out
end

local function brightenKeys(keys: { Key }, amount: number): { Key }
    local out: { Key } = {}
    local a = math.clamp(amount, 0, 1)
    for _, key in keys do
        table.insert(out, {
            t = key.t,
            c = {
                r = clampByte(key.c.r + (255 - key.c.r) * a),
                g = clampByte(key.c.g + (255 - key.c.g) * a),
                b = clampByte(key.c.b + (255 - key.c.b) * a),
            },
        })
    end
    return out
end

local function whiteBandKeys(keys: { Key }): { Key }
    local a = if #keys > 0 then keys[1].c else WHITE
    local b = if #keys > 1 then keys[#keys].c else a
    return {
        { t = 0, c = a },
        { t = 0.32, c = b },
        { t = 0.48, c = WHITE },
        { t = 0.52, c = WHITE },
        { t = 0.68, c = b },
        { t = 1, c = a },
    }
end

local function chromeKeys(keys: { Key }): { Key }
    local base = if #keys > 0 then keys[1].c else { r = 200, g = 200, b = 200 }
    local dark = {
        r = clampByte(base.r * 0.35),
        g = clampByte(base.g * 0.35),
        b = clampByte(base.b * 0.35),
    }
    local lit = {
        r = clampByte(base.r * 0.55 + 120),
        g = clampByte(base.g * 0.55 + 120),
        b = clampByte(base.b * 0.55 + 120),
    }
    return {
        { t = 0, c = dark },
        { t = 0.45, c = lit },
        { t = 0.55, c = WHITE },
        { t = 0.7, c = lit },
        { t = 1, c = dark },
    }
end

local function candyKeys(t: number): { Key }
    local shift = saw(t, 2.5)
    local stops = { 0, 0.2, 0.4, 0.6, 0.8, 1 }
    local out: { Key } = {}
    for _, u in stops do
        table.insert(out, {
            t = u,
            c = hsvToRgb(fract(shift + u), 0.9, 1),
        })
    end
    return out
end

local ColorSheenLogic = {}

local VARIANT_COUNT = 16

function ColorSheenLogic.variantCount(): number
    return VARIANT_COUNT
end

--[[
  Motion (offset/spin) — S1..S8
  Recolor / Roblox-popular — S9..S16
  S1  HardSweep     linear sheen
  S2  SlowSweep
  S3  PingPong
  S4  PauseSweep
  S5  SpinSlow
  S6  FlashPass
  S7  SnapSheen
  S8  Breathe
  S9  WhiteBand     white stripe ColorSequence + sweep (Pet Sim)
  S10 HueShift      shift whole palette hue
  S11 RainbowSolid  solid HSV cycle (classic Roblox)
  S12 DualFlash     alternate first/last palette colors solid
  S13 Chrome        metal band + sweep
  S14 HotPulse      brighten palette in/out
  S15 CandyRainbow  multi-hue gradient + slow spin
  S16 GoldBlink     solid warm A/B flash
]]
function ColorSheenLogic.pose(
    variant: number,
    t: number,
    baseRotation: number,
    baseKeys: { Key }?
): SheenPose
    local base = baseRotation
    local keys = baseKeys
        or {
            { t = 0, c = { r = 255, g = 220, b = 40 } },
            { t = 1, c = { r = 255, g = 100, b = 20 } },
        }

    if variant <= 0 then
        return { offset = ZERO, rotation = base }
    end

    if variant == 1 then
        local u = saw(t, 1.35)
        return { offset = { x = u * 2 - 1, y = 0 }, rotation = base }
    end
    if variant == 2 then
        local u = saw(t, 2.4)
        return { offset = { x = u * 2 - 1, y = 0 }, rotation = base }
    end
    if variant == 3 then
        local p = pingPongLinear(t, 1.8)
        return { offset = { x = p * 2 - 1, y = 0 }, rotation = base }
    end
    if variant == 4 then
        local u = pauseSweep(t, 2.0, 0.18)
        return { offset = { x = u * 2 - 1, y = 0 }, rotation = base }
    end
    if variant == 5 then
        return { offset = ZERO, rotation = (base + t * 40) % 360 }
    end
    if variant == 6 then
        local u = saw(t, 1.5)
        local near = math.abs(u - 0.5)
        return {
            offset = { x = u * 2 - 1, y = 0 },
            rotation = base,
            midTransparency = if near < 0.08 then 0.4 else 0.05,
        }
    end
    if variant == 7 then
        local steps = 5
        local idx = math.min(steps - 1, math.floor(saw(t, 1.6) * steps))
        return {
            offset = { x = (idx / (steps - 1)) * 2 - 1, y = 0 },
            rotation = base,
        }
    end
    if variant == 8 then
        local pulse = pingPongLinear(t, 1.6)
        return {
            offset = ZERO,
            rotation = base,
            midTransparency = 0.05 + pulse * 0.35,
        }
    end
    if variant == 9 then
        local u = saw(t, 1.4)
        return {
            offset = { x = u * 2 - 1, y = 0 },
            rotation = 0,
            keys = whiteBandKeys(keys),
        }
    end
    if variant == 10 then
        return {
            offset = ZERO,
            rotation = base,
            keys = shiftKeys(keys, saw(t, 3.0)),
        }
    end
    if variant == 11 then
        return {
            offset = ZERO,
            rotation = base,
            solid = hsvToRgb(saw(t, 2.2), 0.95, 1),
        }
    end
    if variant == 12 then
        local a = keys[1].c
        local b = keys[#keys].c
        local on = saw(t, 0.5) < 0.5
        return { offset = ZERO, rotation = base, solid = if on then a else b }
    end
    if variant == 13 then
        local u = saw(t, 1.55)
        return {
            offset = { x = u * 2 - 1, y = 0 },
            rotation = 0,
            keys = chromeKeys(keys),
        }
    end
    if variant == 14 then
        local amt = pingPongLinear(t, 1.4)
        return {
            offset = ZERO,
            rotation = base,
            keys = brightenKeys(keys, amt * 0.65),
        }
    end
    if variant == 15 then
        return {
            offset = ZERO,
            rotation = (t * 55) % 360,
            keys = candyKeys(t),
        }
    end
    -- S16 GoldBlink
    local warmA: Rgb = { r = 255, g = 230, b = 60 }
    local warmB: Rgb = { r = 255, g = 140, b = 20 }
    if #keys >= 2 then
        warmA = keys[1].c
        warmB = keys[#keys].c
    end
    local on = saw(t, 0.45) < 0.55
    return { offset = ZERO, rotation = base, solid = if on then warmA else warmB }
end

function ColorSheenLogic.labels(): { [number]: string }
    return {
        [1] = "S1 HardSweep",
        [2] = "S2 SlowSweep",
        [3] = "S3 PingPong",
        [4] = "S4 PauseSweep",
        [5] = "S5 SpinSlow",
        [6] = "S6 FlashPass",
        [7] = "S7 SnapSheen",
        [8] = "S8 Breathe",
        [9] = "S9 WhiteBand",
        [10] = "S10 HueShift",
        [11] = "S11 Rainbow",
        [12] = "S12 DualFlash",
        [13] = "S13 Chrome",
        [14] = "S14 HotPulse",
        [15] = "S15 Candy",
        [16] = "S16 GoldBlink",
    }
end

return ColorSheenLogic
