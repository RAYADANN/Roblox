--!strict
-- Звуковые события. id = 0 до настройки в Creator Hub.

export type SoundEntry = {
	id: string,
	volume: number,
}

local SoundDatabase: { [string]: SoundEntry } = {
	ui_click = { id = "rbxassetid://0", volume = 0.5 },
	ui_confirm = { id = "rbxassetid://0", volume = 0.6 },
	sell_success = { id = "rbxassetid://0", volume = 0.7 },
	sell_fail = { id = "rbxassetid://0", volume = 0.5 },
}

return SoundDatabase
