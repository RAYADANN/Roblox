--!strict
-- Цены плит Area1. Area2 = × AREA2_PRICE_MULT.

export type AreaId = "Area1" | "Area2"
export type PadId = "1" | "2" | "3" | "4" | "5"

local AREA1_PRICES: { [PadId]: number } = {
	["1"] = 1,
	["2"] = 5,
	["3"] = 25,
	["4"] = 100,
	["5"] = 150,
}

local PAD_ORDER: { PadId } = { "1", "2", "3", "4", "5" }

return {
	AREA1_PRICES = AREA1_PRICES,
	PAD_ORDER = PAD_ORDER,
}
