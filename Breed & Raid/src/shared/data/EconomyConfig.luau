--!strict

local EconomyConfig = {
	mpsTickSec = 1,
	starterCash = 500,
	storageCap = 40,
	placeablesCap = 40,
	cashUiWarn = 1e12,
	nestBuyCosts = {
		N5 = 5_000,
		N6 = 15_000,
		N7 = 40_000,
		N8 = 100_000,
	},
	sellMin = 35,
	sellHybridMult = 1.35,
	sellBase = 50,
	sellOneInExp = 0.65,
}

return EconomyConfig
