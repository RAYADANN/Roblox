--!strict

local function shortNumber(n: number): string
    local v = math.floor(n + 0.5)
    if v < 1000 then
        return tostring(v)
    end
    local suffixes = {
        { 1e15, "Qd" },
        { 1e12, "T" },
        { 1e9, "B" },
        { 1e6, "M" },
        { 1e3, "K" },
    }
    for _, pair in suffixes do
        local div = pair[1] :: number
        local suf = pair[2] :: string
        if v >= div then
            return string.format("%.1f%s", v / div, suf)
        end
    end
    return tostring(v)
end

local function money(n: number): string
    return "$" .. shortNumber(n)
end

return { shortNumber = shortNumber, money = money }
