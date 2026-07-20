--!strict

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Mythic" | "Secret"

local RarityLogic = {}

function RarityLogic.fromOneIn(oneIn: number): Rarity
	local n = math.max(2, math.floor(oneIn))
	if n <= 9 then
		return "Common"
	elseif n <= 49 then
		return "Uncommon"
	elseif n <= 199 then
		return "Rare"
	elseif n <= 999 then
		return "Epic"
	elseif n <= 9_999 then
		return "Mythic"
	end
	return "Secret"
end

function RarityLogic.auraId(rarity: Rarity): string
	return `aura_{string.lower(rarity)}`
end

function RarityLogic.bandColor(rarity: Rarity): Color3
	if rarity == "Common" then
		return Color3.fromRGB(180, 185, 200)
	elseif rarity == "Uncommon" then
		return Color3.fromRGB(80, 200, 120)
	elseif rarity == "Rare" then
		return Color3.fromRGB(80, 160, 255)
	elseif rarity == "Epic" then
		return Color3.fromRGB(180, 100, 255)
	elseif rarity == "Mythic" then
		return Color3.fromRGB(255, 200, 60)
	end
	return Color3.fromRGB(220, 40, 60)
end

function RarityLogic.displayScale(genesScale: number, oneIn: number): number
	local bump = 1 + 0.04 * math.log10(math.max(2, oneIn))
	return math.clamp(genesScale * bump, 0.85, 1.55)
end

return RarityLogic
