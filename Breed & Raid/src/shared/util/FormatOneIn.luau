--!strict

-- GDD §4.3A — primary flex display string.

local function formatCompact(n: number): string
	if n < 1_000 then
		return tostring(math.floor(n))
	end
	if n < 1_000_000 then
		local k = n / 1_000
		if k >= 100 or k == math.floor(k) then
			return string.format("%dK", math.floor(k + 0.5))
		end
		return string.format("%.1fK", k)
	end
	local m = n / 1_000_000
	if m >= 100 or m == math.floor(m) then
		return string.format("%dM", math.floor(m + 0.5))
	end
	return string.format("%.1fM", m)
end

local function FormatOneIn(oneIn: number): string
	local n = math.max(2, math.floor(oneIn))
	return `1 in {formatCompact(n)}`
end

return FormatOneIn
