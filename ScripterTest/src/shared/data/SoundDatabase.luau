--!strict
-- Звуки из ReplicatedStorage.Sounds (1 = ачивка, 2 = покупка).

export type SoundEntry = {
	id: string,
	volume: number,
}

local SoundDatabase: { [string]: SoundEntry } = {
	ui_click = { id = "rbxassetid://9113819053", volume = 0.45 },
	ui_confirm = { id = "rbxassetid://9114224577", volume = 0.55 },
	-- ReplicatedStorage.Sounds[2] Steam Achievement
	shop_ok = { id = "rbxassetid://78959439349986", volume = 0.55 },
	-- ReplicatedStorage.Sounds["error sound"]
	shop_fail = { id = "rbxassetid://110775644471689", volume = 0.55 },
	coin_collect = { id = "rbxassetid://9114221327", volume = 0.4 },
	-- ReplicatedStorage.Sounds.achievement_complete
	achievement_unlock = { id = "rbxassetid://4612373756", volume = 0.7 },
}

return SoundDatabase
