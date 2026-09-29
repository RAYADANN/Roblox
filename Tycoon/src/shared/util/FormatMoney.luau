--!strict
-- Shared number formatting for pads and HUD (10K, 100M, …).

local FormatMoney = {}

local function formatScaled(scaled: number, suffix: string): string
    local rounded = math.floor(scaled * 10 + 0.5) / 10
    if rounded >= 100 then
        return tostring(math.floor(rounded + 0.5)) .. suffix
    end
    if rounded == math.floor(rounded) then
        return tostring(math.floor(rounded)) .. suffix
    end
    return string.format("%.1f%s", rounded, suffix)
end

function FormatMoney.short(n: number): string
    local sign = if n < 0 then "-" else ""
    local v = math.abs(math.floor(n + 0.5))
    if v < 1000 then
        return sign .. tostring(v)
    end
    if v < 1_000_000 then
        return sign .. formatScaled(v / 1000, "K")
    end
    if v < 1_000_000_000 then
        return sign .. formatScaled(v / 1_000_000, "M")
    end
    if v < 1_000_000_000_000 then
        return sign .. formatScaled(v / 1_000_000_000, "B")
    end
    return sign .. formatScaled(v / 1_000_000_000_000, "T")
end

--- Rate labels (per-sec deltas): keep one decimal under 1k.
function FormatMoney.rate(n: number): string
    if n >= 1000 or n <= -1000 then
        return FormatMoney.short(n)
    end
    local tenths = math.floor(n * 10 + 0.5) / 10
    if tenths == math.floor(tenths) then
        return tostring(math.floor(tenths))
    end
    return string.format("%.1f", tenths)
end

--- Prefer short abbreviations for UI (alias kept for older call sites).
function FormatMoney.comma(n: number): string
    return FormatMoney.short(n)
end

return FormatMoney
