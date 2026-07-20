--!strict

local CreatureDatabase = require(script.Parent.Parent.data.CreatureDatabase)
local Id = require(script.Parent.Id)
local RarityLogic = require(script.Parent.RarityLogic)
local CreatureTypes = require(script.Parent.Parent.types.Creature)

type CreatureInstance = CreatureTypes.CreatureInstance
type Genes = CreatureTypes.Genes
type CreatureTemplate = CreatureDatabase.CreatureTemplate

local SPECIES_COLORS: { [string]: { Color3 } } = {
	pup = { Color3.fromRGB(210, 170, 120), Color3.fromRGB(90, 60, 40) },
	cat = { Color3.fromRGB(240, 160, 90), Color3.fromRGB(60, 50, 50) },
	fox = { Color3.fromRGB(230, 120, 50), Color3.fromRGB(40, 40, 45) },
	owl = { Color3.fromRGB(180, 160, 130), Color3.fromRGB(50, 70, 90) },
	bug = { Color3.fromRGB(90, 160, 70), Color3.fromRGB(30, 50, 30) },
}

local CreatureFactory = {}

local function colorToTable(c: Color3): { number }
	return { c.R, c.G, c.B }
end

local function defaultGenes(speciesId: string, rarity: RarityLogic.Rarity): Genes
	local palette = SPECIES_COLORS[speciesId] or SPECIES_COLORS.pup
	local faces = CreatureDatabase.faceIds
	return {
		primaryColor = colorToTable(palette[1]),
		secondaryColor = colorToTable(palette[2]),
		faceId = faces[math.random(1, #faces)],
		accHead = nil,
		accBack = nil,
		scale = 1,
		auraId = RarityLogic.auraId(rarity),
	}
end

function CreatureFactory.fromTemplate(template: CreatureTemplate, ownerUserId: number, nestId: string?): CreatureInstance
	local rarity = RarityLogic.fromOneIn(template.oneIn)
	return {
		id = Id.new(),
		templateId = template.templateId,
		speciesId = template.speciesId,
		displayName = template.displayName,
		ownerUserId = ownerUserId,
		oneIn = template.oneIn,
		rarity = rarity,
		mps = template.mps,
		isHybrid = false,
		generation = 0,
		genes = defaultGenes(template.speciesId, rarity),
		nestId = nestId,
		lockedUntil = nil,
		bornAt = os.time(),
	}
end

function CreatureFactory.fromTemplateId(templateId: string, ownerUserId: number, nestId: string?): CreatureInstance?
	local template = CreatureDatabase.getTemplate(templateId)
	if not template then
		return nil
	end
	return CreatureFactory.fromTemplate(template, ownerUserId, nestId)
end

return CreatureFactory
