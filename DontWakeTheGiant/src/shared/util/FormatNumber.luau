--!strict
-- Единое сокращение чисел (GDD 9.6): K, M, B, T, Qa, Qi; три значащие цифры.

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local FormatNumber = {}

function FormatNumber.short(value: number): string
    local sign = if value < 0 then "-" else ""
    local n = math.abs(value)
    if n < 1000 then
        return sign .. tostring(math.floor(n))
    end
    local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
    local scaled = n / 10 ^ (tier * 3)
    -- 999.6K округляется до 1000K: переходим на следующий порядок.
    local decimals = if scaled >= 100 then 0 elseif scaled >= 10 then 1 else 2
    local rounded = math.floor(scaled * 10 ^ decimals) / 10 ^ decimals
    if rounded >= 1000 and tier < #SUFFIXES - 1 then
        tier += 1
        rounded = math.floor(rounded / 1000 * 100) / 100
        decimals = 2
    end
    local text = string.format(`%.{decimals}f`, rounded)
    if string.find(text, "%.") then
        text = string.gsub(string.gsub(text, "0+$", ""), "%.$", "")
    end
    return sign .. text .. SUFFIXES[tier + 1]
end

return FormatNumber
