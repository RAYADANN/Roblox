--!strict

local Constants = if script
	then require(script.Parent.Parent.data.Constants)
	else require("@shared/data/Constants")

export type CoinColor = "yellow" | "red"

local CoinLogic = {}

function CoinLogic.pointsPerCoin(): number
	return Constants.COIN_POINTS
end

function CoinLogic.maxPerArea(): number
	return Constants.COIN_MAX_PER_AREA
end

function CoinLogic.canSpawn(currentCount: number): boolean
	return currentCount < Constants.COIN_MAX_PER_AREA
end

function CoinLogic.colorForArea(areaId: string): CoinColor
	if areaId == "Area2" then
		return "red"
	end
	return "yellow"
end

function CoinLogic.rgbForColor(color: CoinColor): (number, number, number)
	if color == "red" then
		return 255, 60, 60
	end
	return 255, 220, 40
end

--- Локальный offset на плоскости зоны (X/Z).
function CoinLogic.randomOffset(areaSizeX: number, areaSizeZ: number, margin: number?): (number, number)
	local m = margin or Constants.COIN_SPAWN_MARGIN
	local halfX = math.max(0, areaSizeX / 2 - m)
	local halfZ = math.max(0, areaSizeZ / 2 - m)
	local x = (math.random() * 2 - 1) * halfX
	local z = (math.random() * 2 - 1) * halfZ
	return x, z
end

return CoinLogic
