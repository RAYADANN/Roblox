--!strict

local CreatureDatabase = require(script.Parent.Parent.data.CreatureDatabase)
local BlockDatabase = require(script.Parent.Parent.data.BlockDatabase)
local RarityLogic = require(script.Parent.RarityLogic)

type CreatureTemplate = CreatureDatabase.CreatureTemplate
type BlockTemplate = BlockDatabase.BlockTemplate

local RollLogic = {}

local function weightedPick<T>(rows: { T }, getWeight: (T) -> number, luckMultFor: ((T) -> number)?): T?
	local total = 0
	local weights = table.create(#rows)
	for i, row in rows do
		local w = getWeight(row)
		if luckMultFor then
			w *= luckMultFor(row)
		end
		weights[i] = w
		total += w
	end
	if total <= 0 then
		return nil
	end
	local roll = math.random() * total
	local acc = 0
	for i, row in rows do
		acc += weights[i]
		if roll <= acc then
			return row
		end
	end
	return rows[#rows]
end

function RollLogic.pickCreatureTemplate(luckLevel: number): CreatureTemplate?
	local luckMult = if luckLevel >= 2 then 2 elseif luckLevel >= 1 then 1.5 else 1
	return weightedPick(CreatureDatabase.templates, function(t)
		return t.weight
	end, function(t)
		if t.oneIn >= 200 then
			return luckMult
		end
		return 1
	end)
end

function RollLogic.pickBlockTemplate(): BlockTemplate?
	return weightedPick(BlockDatabase.templates, function(t)
		return t.weight
	end, nil)
end

function RollLogic.creaturePreviewFromTemplate(template: CreatureTemplate): {
	kind: string,
	templateId: string,
	displayName: string,
	oneIn: number,
	rarity: string,
	buyCost: number,
	mps: number?,
	grantQty: number?,
}
	return {
		kind = "creature",
		templateId = template.templateId,
		displayName = template.displayName,
		oneIn = template.oneIn,
		rarity = RarityLogic.fromOneIn(template.oneIn),
		buyCost = template.buyCost,
		mps = template.mps,
		grantQty = nil,
	}
end

function RollLogic.blockPreviewFromTemplate(template: BlockTemplate): {
	kind: string,
	templateId: string,
	displayName: string,
	oneIn: number,
	rarity: string,
	buyCost: number,
	mps: number?,
	grantQty: number?,
}
	return {
		kind = "block",
		templateId = template.id,
		displayName = template.id,
		oneIn = template.oneIn,
		rarity = template.rarity,
		buyCost = template.buyCost,
		mps = nil,
		grantQty = template.grantQty,
	}
end

return RollLogic
