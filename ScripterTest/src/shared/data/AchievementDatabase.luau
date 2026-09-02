--!strict

export type AchievementId = "buyAllArea1" | "buyAllArea2" | "fallOffMap" | "jumpFiveTimes"

export type AchievementDef = {
	id: AchievementId,
	title: string,
	description: string,
	order: number,
}

local LIST: { AchievementDef } = {
	{
		id = "buyAllArea1",
		title = "Покупатель Area1",
		description = "Купить все плиты в Area1",
		order = 1,
	},
	{
		id = "buyAllArea2",
		title = "Покупатель Area2",
		description = "Купить все плиты в Area2",
		order = 2,
	},
	{
		id = "fallOffMap",
		title = "Прыжок в бездну",
		description = "Спрыгнуть за пределы карты",
		order = 3,
	},
	{
		id = "jumpFiveTimes",
		title = "Прыгун",
		description = "Прыгнуть пять раз",
		order = 4,
	},
}

return {
	LIST = LIST,
}
