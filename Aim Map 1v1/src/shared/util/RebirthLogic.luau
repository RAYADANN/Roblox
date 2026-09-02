--!strict
-- Pure logic: формулы rebirth. Тестируется в CI (Lune).
--# selene: allow(incorrect_standard_library_use)

local Constants = if script
    then require(script.Parent.Parent.data.Constants)
    else require("@shared/data/Constants")

local RebirthLogic = {}

function RebirthLogic.cost(rebirths: number): number
    return math.floor(Constants.REBIRTH_BASE_COST * Constants.REBIRTH_EXPONENT ^ rebirths)
end

function RebirthLogic.valueMultiplier(rebirths: number): number
    return 1 + rebirths * Constants.REBIRTH_MULT_PER
end

return RebirthLogic
