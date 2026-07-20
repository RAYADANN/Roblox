--!strict

--[[
	Placeables (walls / traps / lamps) — GDD §4F.
	Buy wall/trap → always +100. Lamp → +1.
]]

export type PlaceableDef = {
	id: string,
	kind: "wall" | "trap" | "lamp",
	displayName: string,
	rarity: string,
	oneIn: number,
	weight: number,
	buyCost: number,
	grantQty: number,
	batHitsToBreak: number,
	color: Color3,
	material: Enum.Material,
	slowFactor: number?,
	damagePerSec: number?,
	lightRadius: number?,
	lampTier: number?,
}

local placeables: { [string]: PlaceableDef } = {
	dirt = {
		id = "dirt",
		kind = "wall",
		displayName = "Dirt Block",
		rarity = "Common",
		oneIn = 2,
		weight = 500,
		buyCost = 450,
		grantQty = 100,
		batHitsToBreak = 1,
		color = Color3.fromRGB(110, 80, 50),
		material = Enum.Material.Ground,
	},
	wood_planks = {
		id = "wood_planks",
		kind = "wall",
		displayName = "Wood Planks",
		rarity = "Uncommon",
		oneIn = 15,
		weight = 80,
		buyCost = 2500,
		grantQty = 100,
		batHitsToBreak = 1,
		color = Color3.fromRGB(140, 100, 55),
		material = Enum.Material.WoodPlanks,
	},
	stone = {
		id = "stone",
		kind = "wall",
		displayName = "Stone",
		rarity = "Rare",
		oneIn = 50,
		weight = 25,
		buyCost = 12000,
		batHitsToBreak = 3,
		grantQty = 100,
		color = Color3.fromRGB(120, 120, 125),
		material = Enum.Material.Slate,
	},
	spikes = {
		id = "spikes",
		kind = "trap",
		displayName = "Spikes",
		rarity = "Uncommon",
		oneIn = 20,
		weight = 60,
		buyCost = 3000,
		grantQty = 100,
		batHitsToBreak = 1,
		color = Color3.fromRGB(160, 40, 40),
		material = Enum.Material.Metal,
		slowFactor = 0.5,
	},
	lamp_t1 = {
		id = "lamp_t1",
		kind = "lamp",
		displayName = "Lamp T1",
		rarity = "Uncommon",
		oneIn = 25,
		weight = 50,
		buyCost = 5000,
		grantQty = 1,
		batHitsToBreak = 1,
		color = Color3.fromRGB(255, 220, 120),
		material = Enum.Material.Neon,
		lightRadius = 14,
		lampTier = 1,
	},
}

local BuildConfig = {
	CELL_SIZE = 4,
	-- Yard columns (symmetric 10×10 covering [-20, 20))
	GRID_MIN = -5,
	GRID_MAX = 4,
	MAX_Y = 0, -- PROVE: 1 layer
	MAX_PLACEABLES = 40,
	CUBE_SIZE = Vector3.new(4, 4, 4),
	FLOOR_TOP_Y = 1,
	YARD_SIZE = 40,
	HUB_DEPTH = 24,
	HUB_WIDTH = 24,
	SpinCostBlock = 0, -- pay on Buy
	SpinCostPet = 0,
}

function BuildConfig.cellKey(cx: number, cy: number, cz: number): string
	return string.format("%d_%d_%d", cx, cy, cz)
end

function BuildConfig.cellToLocal(cx: number, cy: number, cz: number): Vector3
	local cell = BuildConfig.CELL_SIZE
	local y = BuildConfig.FLOOR_TOP_Y + cell * 0.5 + cy * cell
	return Vector3.new(cx * cell + cell * 0.5, y, cz * cell + cell * 0.5)
end

function BuildConfig.worldToCell(origin: CFrame, worldPos: Vector3): (number, number, number)
	local localPos = origin:PointToObjectSpace(worldPos)
	local cell = BuildConfig.CELL_SIZE
	local cx = math.floor(localPos.X / cell)
	local cz = math.floor(localPos.Z / cell)
	local cy = math.floor((localPos.Y - BuildConfig.FLOOR_TOP_Y) / cell)
	return cx, cy, cz
end

function BuildConfig.inYardBounds(cx: number, cz: number): boolean
	return cx >= BuildConfig.GRID_MIN
		and cx <= BuildConfig.GRID_MAX
		and cz >= BuildConfig.GRID_MIN
		and cz <= BuildConfig.GRID_MAX
end

function BuildConfig.inHeight(cy: number): boolean
	return cy >= 0 and cy <= BuildConfig.MAX_Y
end

function BuildConfig.isBuildableCell(cx: number, cy: number, cz: number): boolean
	return BuildConfig.inYardBounds(cx, cz) and BuildConfig.inHeight(cy)
end

local function rollBlockId(rng: Random?): string
	local random = rng or Random.new()
	local total = 0
	for _, def in placeables do
		total += def.weight
	end
	local pick = random:NextNumber(0, total)
	local acc = 0
	local fallback = "dirt"
	for id, def in placeables do
		acc += def.weight
		fallback = id
		if pick <= acc then
			return id
		end
	end
	return fallback
end

local BlockDatabase = {
	Config = BuildConfig,
	Placeables = placeables,
	rollBlockId = rollBlockId,
}

setmetatable(BlockDatabase, {
	__index = placeables,
})

return BlockDatabase :: typeof(placeables) & {
	Config: typeof(BuildConfig),
	Placeables: typeof(placeables),
	rollBlockId: (rng: Random?) -> string,
}
