--!strict
-- Pure logic: rebirth cost / auction value mult / progress. CI-tested (Lune).

local Constants
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
else
    Constants = require("../data/Constants")
end

local RebirthLogic = {}

function RebirthLogic.cost(rebirths: number): number
    return math.floor(Constants.REBIRTH_BASE_COST * Constants.REBIRTH_EXPONENT ^ rebirths)
end

function RebirthLogic.valueMultiplier(rebirths: number): number
    return 1 + rebirths * Constants.REBIRTH_MULT_PER
end

function RebirthLogic.canAfford(coins: number, rebirths: number): boolean
    return coins >= RebirthLogic.cost(rebirths)
end

--- Progress toward next rebirth: (current, required). Current is capped at required.
function RebirthLogic.progress(coins: number, rebirths: number): (number, number)
    local need = RebirthLogic.cost(rebirths)
    return math.min(math.max(coins, 0), need), need
end

function RebirthLogic.progressFraction(coins: number, rebirths: number): number
    local have, need = RebirthLogic.progress(coins, rebirths)
    if need <= 0 then
        return 1
    end
    return have / need
end

--- Label for the coin-mult perk after the next rebirth (e.g. "X2 Coins").
function RebirthLogic.coinRewardLabel(rebirths: number): string
    local mult = RebirthLogic.valueMultiplier(rebirths + 1)
    local text = if mult == math.floor(mult)
        then tostring(math.floor(mult))
        else string.format("%.1f", mult)
    return `X{text} Coins`
end

return RebirthLogic
