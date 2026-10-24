--!strict
-- Единый визуальный язык пресетов. Pure RGB (0–255) — CI без Color3.

export type Rgb = { number } -- {r, g, b}

export type Palette = {
    neon: Rgb,
    spark: Rgb,
    smoke: Rgb,
    heal: Rgb,
    crit: Rgb,
    cast: Rgb,
    impact: Rgb,
}

local StyleTokens = {
    palette = {
        neon = { 90, 230, 255 },
        spark = { 255, 230, 140 },
        smoke = { 75, 82, 98 },
        heal = { 90, 255, 170 },
        crit = { 255, 70, 120 },
        cast = { 255, 210, 90 },
        impact = { 160, 220, 255 },
    } :: Palette,

    --- Stagger timings (sec) — AAA layering: flash → shake → body → recovery
    timing = {
        anticipate = 0,
        flash = 0.02,
        peak = 0.05,
        body = 0.08,
        recovery = 0.28,
        tail = 0.45,
    },

    priorityIntensity = {
        Low = 0.7,
        Medium = 1,
        High = 1.15,
        Critical = 1.35,
    },
}

function StyleTokens.rgb(key: string): Rgb
    local p = (StyleTokens.palette :: { [string]: Rgb })[key]
    if p then
        return p
    end
    return StyleTokens.palette.impact
end

return StyleTokens
