--!strict

local EconomyConfig = require(script.Parent.Parent.data.EconomyConfig)

local EconomyLogic = {}

function EconomyLogic.sellPrice(oneIn: number, isHybrid: boolean): number
	local hybridMult = if isHybrid then EconomyConfig.sellHybridMult else 1
	local price = math.floor(EconomyConfig.sellBase * (oneIn ^ EconomyConfig.sellOneInExp) * hybridMult)
	return math.max(EconomyConfig.sellMin, price)
end

function EconomyLogic.hybridMps(parentAMps: number, parentBMps: number, childOneIn: number, parentAOneIn: number, parentBOneIn: number): number
	local base = math.max(parentAMps, parentBMps)
	local denom = math.max(parentAOneIn, parentBOneIn, 2)
	local mult = 1 + 0.15 * math.log10(math.max(childOneIn, 2) / denom)
	local mps = base * mult
	return math.clamp(mps, base, base * 2.5)
end

function EconomyLogic.sumNestMps(creatures: { [string]: { nestId: string?, mps: number } }): number
	local sum = 0
	for _, creature in creatures do
		if creature.nestId ~= nil then
			sum += creature.mps
		end
	end
	return sum
end

return EconomyLogic
