--!strict
-- Округление чисел для UI и Localization (макс. N знаков после точки, без «1.0»).

local NumberFormat = {}

function NumberFormat.decimal(value: number, decimals: number?): string
	local d = decimals or 1
	if d <= 0 then
		return tostring(math.floor(value + 0.5))
	end
	local mult = 10 ^ d
	local rounded = math.floor(value * mult + 0.5) / mult
	local intPart = math.floor(rounded + 1e-9)
	if math.abs(rounded - intPart) < 1e-9 then
		return tostring(intPart)
	end
	return string.format("%." .. tostring(d) .. "f", rounded)
end

return NumberFormat
