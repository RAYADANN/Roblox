--!strict

local BreedConfig = require(script.Parent.Parent.data.BreedConfig)
local EconomyLogic = require(script.Parent.EconomyLogic)
local Id = require(script.Parent.Id)
local RarityLogic = require(script.Parent.RarityLogic)
local CreatureTypes = require(script.Parent.Parent.types.Creature)

type CreatureInstance = CreatureTypes.CreatureInstance
type Genes = CreatureTypes.Genes
type Rarity = RarityLogic.Rarity

local RARITY_RANK: { [string]: number } = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Mythic = 5,
	Secret = 6,
}

local BreedLogic = {}

local function pickMutateMult(luckBreed: number): number
	local tableRows = BreedConfig.mutate
	-- Breed Luck 1 shifts weights slightly via GDD; PROVE uses base table when luck=0
	local total = 0
	for _, row in tableRows do
		total += row.chance
	end
	local roll = math.random() * total
	local acc = 0
	for _, row in tableRows do
		acc += row.chance
		if roll <= acc then
			return row.mult
		end
	end
	return 1
end

function BreedLogic.rollChildOneIn(parentA: CreatureInstance, parentB: CreatureInstance, luckBreed: number): (number, number)
	local base = parentA.oneIn * parentB.oneIn
	local mult = pickMutateMult(luckBreed)
	local child = if mult < 1 then math.max(2, math.floor(base * mult)) else math.floor(base * mult)
	return math.max(2, child), mult
end

function BreedLogic.mutateLabel(mult: number): string
	if mult >= 10 then
		return "JACKPOT ×10"
	elseif mult >= 5 then
		return "JACKPOT ×5"
	elseif mult >= 2 then
		return "JACKPOT ×2"
	elseif mult < 1 then
		return "WHIFF ×0.5"
	end
	return "NORMAL"
end

function BreedLogic.jackpotCeiling(expectedOneIn: number): number
	return math.max(2, math.floor(expectedOneIn * 10))
end

function BreedLogic.rollOutcome(luckBreed: number): string
	local success = BreedConfig.successChance
	local fail = BreedConfig.failChance
	local burn = BreedConfig.burnChance
	if luckBreed >= 1 then
		success, fail, burn = 0.88, 0.09, 0.03
	end
	local roll = math.random()
	if roll < success then
		return "success"
	elseif roll < success + fail then
		return "fail"
	end
	return "burn"
end

local function lerpColor(a: { number }, b: { number }, t: number): { number }
	return {
		math.clamp(a[1] + (b[1] - a[1]) * t + (math.random() - 0.5) * 0.1, 0, 1),
		math.clamp(a[2] + (b[2] - a[2]) * t + (math.random() - 0.5) * 0.1, 0, 1),
		math.clamp(a[3] + (b[3] - a[3]) * t + (math.random() - 0.5) * 0.1, 0, 1),
	}
end

local function pickAcc(a: string?, b: string?): string?
	local roll = math.random()
	if roll < 0.4 then
		return a
	elseif roll < 0.8 then
		return b
	end
	return nil
end

function BreedLogic.buildHybrid(parentA: CreatureInstance, parentB: CreatureInstance, childOneIn: number): CreatureInstance
	local rankA = RARITY_RANK[parentA.rarity] or 1
	local rankB = RARITY_RANK[parentB.rarity] or 1
	local speciesId: string
	if rankA ~= rankB then
		speciesId = if rankA > rankB then parentA.speciesId else parentB.speciesId
	else
		speciesId = if math.random() < 0.5 then parentA.speciesId else parentB.speciesId
	end

	local generation = math.max(parentA.generation, parentB.generation) + 1
	local rarity = RarityLogic.fromOneIn(childOneIn)
	local scale = math.clamp(((parentA.genes.scale + parentB.genes.scale) / 2) * (1 + 0.05 * generation), 0.85, 1.45)

	local genes: Genes = {
		primaryColor = lerpColor(parentA.genes.primaryColor, parentB.genes.primaryColor, 0.5),
		secondaryColor = parentB.genes.secondaryColor,
		faceId = if math.random() < 0.5 then parentA.genes.faceId else parentB.genes.faceId,
		accHead = pickAcc(parentA.genes.accHead, parentB.genes.accHead),
		accBack = pickAcc(parentA.genes.accBack, parentB.genes.accBack),
		scale = scale,
		auraId = RarityLogic.auraId(rarity),
	}

	local mps = EconomyLogic.hybridMps(parentA.mps, parentB.mps, childOneIn, parentA.oneIn, parentB.oneIn)
	local displayName = `Hybrid {string.upper(string.sub(speciesId, 1, 1))}{string.sub(speciesId, 2)}`

	return {
		id = Id.new(),
		templateId = nil,
		speciesId = speciesId,
		displayName = displayName,
		ownerUserId = parentA.ownerUserId,
		oneIn = childOneIn,
		rarity = rarity,
		mps = mps,
		isHybrid = true,
		generation = generation,
		genes = genes,
		nestId = nil,
		lockedUntil = nil,
		bornAt = os.time(),
	}
end

function BreedLogic.cancelFee(parentA: CreatureInstance, parentB: CreatureInstance): number
	local sum = EconomyLogic.sellPrice(parentA.oneIn, parentA.isHybrid) + EconomyLogic.sellPrice(parentB.oneIn, parentB.isHybrid)
	return math.max(BreedConfig.cancelFeeMin, math.floor(sum * BreedConfig.cancelFeeFraction))
end

function BreedLogic.softSpeedCost(startedAt: number, now: number, firstFree: boolean?): number
	if firstFree then
		return 0
	end
	local elapsed = math.max(0, now - startedAt)
	return math.floor(BreedConfig.softSpeedBase + elapsed * BreedConfig.softSpeedPerElapsed)
end

return BreedLogic
