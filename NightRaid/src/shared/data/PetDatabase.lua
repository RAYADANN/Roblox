--!strict

export type PetDef = {
	id: string,
	displayName: string,
	rarity: string,
	incomePerSec: number,
	rollWeight: number,
	oneIn: number, -- display odds ~1/N
	buyCost: number, -- pay after roll to keep
}

local pets: { [string]: PetDef } = {
	scrap_pup = {
		id = "scrap_pup",
		displayName = "Scrap Pup",
		rarity = "Common",
		incomePerSec = 1,
		rollWeight = 500,
		oneIn = 2,
		buyCost = 40,
	},
	copper_cat = {
		id = "copper_cat",
		displayName = "Copper Cat",
		rarity = "Common",
		incomePerSec = 1.2,
		rollWeight = 500,
		oneIn = 2,
		buyCost = 50,
	},
	glow_fox = {
		id = "glow_fox",
		displayName = "Glow Fox",
		rarity = "Uncommon",
		incomePerSec = 3,
		rollWeight = 200,
		oneIn = 5,
		buyCost = 150,
	},
	volt_owl = {
		id = "volt_owl",
		displayName = "Volt Owl",
		rarity = "Rare",
		incomePerSec = 10,
		rollWeight = 50,
		oneIn = 20,
		buyCost = 500,
	},
	night_hound = {
		id = "night_hound",
		displayName = "Night Hound",
		rarity = "Epic",
		incomePerSec = 40,
		rollWeight = 10,
		oneIn = 100,
		buyCost = 2000,
	},
	void_drake = {
		id = "void_drake",
		displayName = "Void Drake",
		rarity = "Mythic",
		incomePerSec = 200,
		rollWeight = 1,
		oneIn = 1000,
		buyCost = 12000,
	},
}

local function rollPetId(rng: Random?): string
	local random = rng or Random.new()
	local total = 0
	for _, def in pets do
		total += def.rollWeight
	end
	local pick = random:NextNumber(0, total)
	local acc = 0
	local fallback = "scrap_pup"
	for id, def in pets do
		acc += def.rollWeight
		fallback = id
		if pick <= acc then
			return id
		end
	end
	return fallback
end

local PetDatabase = {
	SpinCost = 0, -- pay on Buy (GDD)
	rollPetId = rollPetId,
}

setmetatable(PetDatabase, {
	__index = pets,
})

return PetDatabase :: typeof(pets) & {
	SpinCost: number,
	rollPetId: (rng: Random?) -> string,
}
