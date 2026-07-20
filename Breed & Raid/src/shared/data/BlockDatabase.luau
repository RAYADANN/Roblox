--!strict

export type BlockTemplate = {
	id: string,
	kind: string,
	rarity: string,
	oneIn: number,
	buyCost: number,
	grantQty: number,
	batHits: number,
	effect: string,
	weight: number,
}

local BlockDatabase = {
	templates = {
		{
			id = "dirt",
			kind = "wall",
			rarity = "Common",
			oneIn = 2,
			buyCost = 450,
			grantQty = 100,
			batHits = 1,
			effect = "wall",
			weight = 40,
		},
		{
			id = "wood_planks",
			kind = "wall",
			rarity = "Uncommon",
			oneIn = 15,
			buyCost = 2_500,
			grantQty = 100,
			batHits = 1,
			effect = "wall",
			weight = 25,
		},
		{
			id = "stone",
			kind = "wall",
			rarity = "Rare",
			oneIn = 50,
			buyCost = 12_000,
			grantQty = 100,
			batHits = 3,
			effect = "wall",
			weight = 15,
		},
		{
			id = "spikes",
			kind = "trap",
			rarity = "Uncommon",
			oneIn = 20,
			buyCost = 3_000,
			grantQty = 100,
			batHits = 1,
			effect = "slow",
			weight = 12,
		},
		{
			id = "nest_deco",
			kind = "deco",
			rarity = "Uncommon",
			oneIn = 25,
			buyCost = 2_000,
			grantQty = 100,
			batHits = 1,
			effect = "visual",
			weight = 8,
		},
	} :: { BlockTemplate },

	starterDirt = 100,
	starterSpikes = 25,
}

function BlockDatabase.get(id: string): BlockTemplate?
	for _, row in BlockDatabase.templates do
		if row.id == id then
			return row
		end
	end
	return nil
end

return BlockDatabase
