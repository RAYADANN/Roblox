--!strict

local BreedConfig = {
	incubateSec = 120,
	successChance = 0.85,
	failChance = 0.10,
	burnChance = 0.05,
	cancelFeeFraction = 0.25,
	cancelFeeMin = 50,
	softSpeedBase = 100,
	softSpeedPerElapsed = 2,
	-- First speed-up of a job is free so the chase loop doesn't die on a 120s dead wait (GDD soft-speed still exists).
	firstSpeedFree = true,
	incubatorSlotsDefault = 1,

	mutate = {
		{ chance = 0.55, mult = 1 },
		{ chance = 0.25, mult = 2 },
		{ chance = 0.12, mult = 5 },
		{ chance = 0.05, mult = 10 },
		{ chance = 0.03, mult = 0.5 },
	},
}

return BreedConfig
