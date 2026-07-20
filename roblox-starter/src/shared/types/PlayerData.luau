--!strict
-- Схема профиля игрока. Единственный источник правды для персистентных данных.

export type UpgradeLevels = { [string]: number }

export type PlayerData = {
	coins: number,
	rebirths: number,
	upgrades: UpgradeLevels,
	firstSessionComplete: boolean,
}

local TEMPLATE: PlayerData = {
	coins = 500,
	rebirths = 0,
	upgrades = {},
	firstSessionComplete = false,
}

return {
	TEMPLATE = TEMPLATE,
}
