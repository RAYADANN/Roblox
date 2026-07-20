--!strict
-- Pure logic: формулы rebirth. Тестируется в CI (Lune).

local Constants = require(script.Parent.Parent.data.Constants)

local RebirthLogic = {}

function RebirthLogic.cost(rebirths: number): number
	return math.floor(Constants.REBIRTH_BASE_COST * Constants.REBIRTH_EXPONENT ^ rebirths)
end

function RebirthLogic.valueMultiplier(rebirths: number): number
	return 1 + rebirths * Constants.REBIRTH_MULT_PER
end

return RebirthLogic
