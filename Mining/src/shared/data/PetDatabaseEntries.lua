--!strict
-- Сырые записи питомцев (30 шт., по одной 3D-модели на пета из PetKit).

export type PetEffectKind = "damageBoost" | "luckBoost" | "coinBoost" | "multiMine"
export type PetRarity = "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic"

export type PetEffect = {
	kind: PetEffectKind,
	value: number,
}

export type Pet = {
	id: string,
	name: string,
	rarity: PetRarity,
	icon: string,
	modelName: string,
	color: Color3,
	effect: PetEffect,
}

local function pet(
	id: string,
	name: string,
	rarity: PetRarity,
	icon: string,
	modelName: string,
	color: Color3,
	kind: PetEffectKind,
	value: number
): Pet
	return {
		id = id,
		name = name,
		rarity = rarity,
		icon = icon,
		modelName = modelName,
		color = color,
		effect = { kind = kind, value = value },
	}
end

local C = Color3.fromRGB

-- name хранит locale-ключ (pet.{id}.name) → резолвится через L() на клиенте
-- (PetCard, EggShopPetTile, PetHatchFX, EggShopModal). id стабильны.
local PETS: { Pet } = {
	-- common ×6
	pet("pebble_pup", "pet.pebble_pup.name", "common", "🐀", "rat", C(170, 160, 150), "damageBoost", 0.10),
	pet("coin_chick", "pet.coin_chick.name", "common", "🐤", "chicken", C(200, 190, 120), "coinBoost", 0.10),
	pet("spot_lady", "pet.spot_lady.name", "common", "🐞", "ladybug", C(220, 60, 80), "luckBoost", 0.10),
	pet("nut_squirrel", "pet.nut_squirrel.name", "common", "🐿️", "squirrel", C(180, 130, 90), "coinBoost", 0.10),
	pet("sand_snake", "pet.sand_snake.name", "common", "🐍", "snake", C(160, 180, 100), "damageBoost", 0.10),
	pet("pink_flamingo", "pet.pink_flamingo.name", "common", "🦩", "flamingo", C(255, 120, 180), "luckBoost", 0.10),

	-- uncommon ×6
	pet("mole_digger", "pet.mole_digger.name", "uncommon", "🪱", "worm", C(120, 200, 120), "damageBoost", 0.20),
	pet("lucky_cat", "pet.lucky_cat.name", "uncommon", "🐱", "cat", C(120, 210, 140), "luckBoost", 0.20),
	pet("cave_bat", "pet.cave_bat.name", "uncommon", "🦇", "bat", C(90, 80, 120), "luckBoost", 0.20),
	pet("ice_seal", "pet.ice_seal.name", "uncommon", "🦭", "seal", C(190, 210, 230), "coinBoost", 0.20),
	pet("dune_serpent", "pet.dune_serpent.name", "uncommon", "🐍", "desert snake", C(210, 170, 90), "damageBoost", 0.20),
	pet("wave_dolphin", "pet.wave_dolphin.name", "uncommon", "🐬", "dolphin", C(80, 170, 230), "coinBoost", 0.20),

	-- rare ×6
	pet("gem_fox", "pet.gem_fox.name", "rare", "🦊", "fox", C(60, 140, 255), "coinBoost", 0.25),
	pet("drill_bot", "pet.drill_bot.name", "rare", "🐝", "bee", C(80, 150, 255), "multiMine", 0.15),
	pet("reef_shark", "pet.reef_shark.name", "rare", "🦈", "shark", C(100, 150, 200), "damageBoost", 0.25),
	pet("sand_scorpion", "pet.sand_scorpion.name", "rare", "🦂", "scorpion", C(200, 120, 60), "multiMine", 0.15),
	pet("tusk_walrus", "pet.tusk_walrus.name", "rare", "🦭", "walrus", C(150, 170, 190), "coinBoost", 0.25),
	pet("meadow_bull", "pet.meadow_bull.name", "rare", "🐂", "bull", C(160, 100, 70), "damageBoost", 0.25),

	-- epic ×5
	pet("crystal_owl", "pet.crystal_owl.name", "epic", "🦉", "owl", C(180, 60, 220), "damageBoost", 0.40),
	pet("midas_hound", "pet.midas_hound.name", "epic", "🦚", "goldenpeacock", C(230, 190, 60), "coinBoost", 0.40),
	pet("swamp_croc", "pet.swamp_croc.name", "epic", "🐊", "crocodile", C(70, 150, 90), "multiMine", 0.22),
	pet("jungle_titan", "pet.jungle_titan.name", "epic", "🐘", "elephant", C(140, 130, 150), "damageBoost", 0.40),
	pet("river_hippo", "pet.river_hippo.name", "epic", "🦛", "hippo", C(120, 150, 180), "coinBoost", 0.40),

	-- legendary ×4
	pet("phoenix_drake", "pet.phoenix_drake.name", "legendary", "🐉", "dragon", C(255, 160, 0), "multiMine", 0.30),
	pet("sky_sovereign", "pet.sky_sovereign.name", "legendary", "🦅", "eagle", C(200, 180, 100), "damageBoost", 0.55),
	pet("royal_peacock", "pet.royal_peacock.name", "legendary", "🦚", "peacock", C(100, 200, 255), "luckBoost", 0.55),
	pet("frost_ram", "pet.frost_ram.name", "legendary", "🐏", "snow ram", C(220, 235, 255), "coinBoost", 0.55),

	-- mythic ×3
	pet("void_titan", "pet.void_titan.name", "mythic", "👾", "SUPER FOX", C(255, 60, 60), "damageBoost", 1.00),
	pet("thunder_buffalo", "pet.thunder_buffalo.name", "mythic", "🐃", "buffalo", C(180, 140, 90), "damageBoost", 0.85),
	pet("star_penguin", "pet.star_penguin.name", "mythic", "🐧", "penguin", C(80, 180, 255), "multiMine", 0.45),
}

return PETS
