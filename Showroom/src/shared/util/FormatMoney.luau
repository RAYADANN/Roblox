--!strict
-- Shared number formatting for pads and HUD (Tycoon parity).

local FormatMoney = {}

function FormatMoney.short(n: number): string
    local v = math.floor(n + 0.5)
    if v < 1000 then
        return tostring(v)
    end
    if v < 1_000_000 then
        return string.format("%.1fK", v / 1000)
    end
    if v < 1_000_000_000 then
        return string.format("%.1fM", v / 1_000_000)
    end
    return string.format("%.1fB", v / 1_000_000_000)
end

function FormatMoney.comma(n: number): string
    local sign = if n < 0 then "-" else ""
    local v = math.abs(math.floor(n + 0.5))
    local formatted = tostring(v):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted
end

return FormatMoney
