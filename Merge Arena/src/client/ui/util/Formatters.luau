--!strict

local function shortNumber(n: number): string
    if n < 1000 then
        return tostring(math.floor(n))
    end
    if n < 1_000_000 then
        return string.format("%.1fK", n / 1000)
    end
    if n < 1_000_000_000 then
        return string.format("%.1fM", n / 1_000_000)
    end
    return string.format("%.1fB", n / 1_000_000_000)
end

return { shortNumber = shortNumber }
