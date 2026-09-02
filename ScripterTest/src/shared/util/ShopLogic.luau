--!strict

local Constants = if script
	then require(script.Parent.Parent.data.Constants)
	else require("@shared/data/Constants")
local ShopDatabase = if script
	then require(script.Parent.Parent.data.ShopDatabase)
	else require("@shared/data/ShopDatabase")

type AreaId = ShopDatabase.AreaId
type PadId = ShopDatabase.PadId

local ShopLogic = {}

function ShopLogic.isValidArea(areaId: string): boolean
	return areaId == "Area1" or areaId == "Area2"
end

function ShopLogic.isValidPad(padId: string): boolean
	return ShopDatabase.AREA1_PRICES[padId :: PadId] ~= nil
end

function ShopLogic.price(areaId: string, padId: string): number?
	if not ShopLogic.isValidArea(areaId) or not ShopLogic.isValidPad(padId) then
		return nil
	end
	local base = ShopDatabase.AREA1_PRICES[padId :: PadId]
	if areaId == "Area2" then
		return base * Constants.AREA2_PRICE_MULT
	end
	return base
end

function ShopLogic.canAfford(points: number, cost: number): boolean
	return points >= cost
end

function ShopLogic.padBit(padId: string): number?
	local n = tonumber(padId)
	if n == nil or n < 1 or n > Constants.SHOP_PAD_COUNT then
		return nil
	end
	return bit32.lshift(1, n - 1)
end

function ShopLogic.maskHasPad(mask: number, padId: string): boolean
	local bit = ShopLogic.padBit(padId)
	if bit == nil then
		return false
	end
	return bit32.band(mask, bit) ~= 0
end

function ShopLogic.maskWithPad(mask: number, padId: string): number
	local bit = ShopLogic.padBit(padId)
	if bit == nil then
		return mask
	end
	return bit32.bor(mask, bit)
end

function ShopLogic.maskFromPads(pads: { [string]: boolean }): number
	local mask = 0
	for _, padId in ShopDatabase.PAD_ORDER do
		if pads[padId] then
			mask = ShopLogic.maskWithPad(mask, padId)
		end
	end
	return mask
end

function ShopLogic.allPadsBought(pads: { [string]: boolean }): boolean
	for _, padId in ShopDatabase.PAD_ORDER do
		if not pads[padId] then
			return false
		end
	end
	return true
end

function ShopLogic.fullMask(): number
	return bit32.lshift(1, Constants.SHOP_PAD_COUNT) - 1
end

return ShopLogic
