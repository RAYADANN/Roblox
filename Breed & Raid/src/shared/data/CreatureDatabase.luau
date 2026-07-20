--!strict

export type CreatureTemplate = {
	templateId: string,
	speciesId: string,
	oneIn: number,
	weight: number,
	buyCost: number,
	mps: number,
	displayName: string,
}

local CreatureDatabase = {
	speciesIds = { "pup", "cat", "fox", "owl", "bug" },

	templates = {
		{
			templateId = "pup_c",
			speciesId = "pup",
			oneIn = 2,
			weight = 28,
			buyCost = 100,
			mps = 1,
			displayName = "Scrap Pup",
		},
		{
			templateId = "cat_c",
			speciesId = "cat",
			oneIn = 3,
			weight = 22,
			buyCost = 120,
			mps = 1.2,
			displayName = "Copper Cat",
		},
		{
			templateId = "bug_c",
			speciesId = "bug",
			oneIn = 5,
			weight = 14,
			buyCost = 180,
			mps = 1.5,
			displayName = "Lint Bug",
		},
		{
			templateId = "fox_u",
			speciesId = "fox",
			oneIn = 12,
			weight = 12,
			buyCost = 500,
			mps = 4,
			displayName = "Glow Fox",
		},
		{
			templateId = "owl_u",
			speciesId = "owl",
			oneIn = 18,
			weight = 8,
			buyCost = 750,
			mps = 5,
			displayName = "Volt Owl",
		},
		{
			templateId = "pup_r",
			speciesId = "pup",
			oneIn = 50,
			weight = 6,
			buyCost = 3_000,
			mps = 12,
			displayName = "Iron Pup",
		},
		{
			templateId = "cat_r",
			speciesId = "cat",
			oneIn = 75,
			weight = 4,
			buyCost = 4_500,
			mps = 15,
			displayName = "Sapphire Cat",
		},
		{
			templateId = "fox_e",
			speciesId = "fox",
			oneIn = 200,
			weight = 3,
			buyCost = 25_000,
			mps = 55,
			displayName = "Neon Fox",
		},
		{
			templateId = "owl_e",
			speciesId = "owl",
			oneIn = 350,
			weight = 2,
			buyCost = 40_000,
			mps = 70,
			displayName = "Storm Owl",
		},
		{
			templateId = "bug_m",
			speciesId = "bug",
			oneIn = 1_000,
			weight = 0.7,
			buyCost = 200_000,
			mps = 220,
			displayName = "Void Bug",
		},
		{
			templateId = "fox_m",
			speciesId = "fox",
			oneIn = 2_500,
			weight = 0.25,
			buyCost = 500_000,
			mps = 280,
			displayName = "Myth Fox",
		},
		{
			templateId = "owl_s",
			speciesId = "owl",
			oneIn = 10_000,
			weight = 0.05,
			buyCost = 2_000_000,
			mps = 400,
			displayName = "Glitch Owl",
		},
	} :: { CreatureTemplate },

	starterGrants = {
		{ templateId = "pup_c", nestId = "N1" },
		{ templateId = "cat_c", nestId = "N2" },
	},

	faceIds = { "face_1", "face_2", "face_3", "face_4", "face_5", "face_6" },
}

function CreatureDatabase.getTemplate(templateId: string): CreatureTemplate?
	for _, row in CreatureDatabase.templates do
		if row.templateId == templateId then
			return row
		end
	end
	return nil
end

return CreatureDatabase
