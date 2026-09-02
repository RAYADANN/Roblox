--!strict
-- Схема профиля. Очки + покупки плит + достижения.

export type ShopPadState = { [string]: boolean }

export type ShopState = {
	Area1: ShopPadState,
	Area2: ShopPadState,
}

export type AchievementState = {
	buyAllArea1: boolean,
	buyAllArea2: boolean,
	fallOffMap: boolean,
	jumpFiveTimes: boolean,
}

export type PlayerData = {
	points: number,
	shop: ShopState,
	achievements: AchievementState,
	jumpCount: number,
	firstSessionComplete: boolean,
}

local function emptyPads(): ShopPadState
	return {
		["1"] = false,
		["2"] = false,
		["3"] = false,
		["4"] = false,
		["5"] = false,
	}
end

local TEMPLATE: PlayerData = {
	points = 0,
	shop = {
		Area1 = emptyPads(),
		Area2 = emptyPads(),
	},
	achievements = {
		buyAllArea1 = false,
		buyAllArea2 = false,
		fallOffMap = false,
		jumpFiveTimes = false,
	},
	jumpCount = 0,
	firstSessionComplete = false,
}

return {
	TEMPLATE = TEMPLATE,
	emptyPads = emptyPads,
}
