--!strict
-- Звуковые события. VFX ids — рабочие Roblox free sounds; ui_* = 0 до Creator Hub.

export type SoundEntry = {
	id: string,
	volume: number,
}

local SoundDatabase: { [string]: SoundEntry } = {
	ui_click = { id = "rbxassetid://0", volume = 0.5 },
	ui_confirm = { id = "rbxassetid://0", volume = 0.6 },
	sell_success = { id = "rbxassetid://0", volume = 0.7 },
	sell_fail = { id = "rbxassetid://0", volume = 0.5 },

	-- World VFX (Roblox catalog / classic; pcall-safe if revoked)
	vfx_impact = { id = "rbxassetid://9114224577", volume = 0.55 },
	vfx_crit = { id = "rbxassetid://9113849571", volume = 0.7 },
	vfx_cast = { id = "rbxassetid://9113819053", volume = 0.5 },
	vfx_whoosh = { id = "rbxassetid://9113818650", volume = 0.4 },
	vfx_spark = { id = "rbxassetid://9114221327", volume = 0.35 },
	vfx_heal = { id = "rbxassetid://9113839663", volume = 0.45 },
	vfx_slam = { id = "rbxassetid://9113849381", volume = 0.65 },
	vfx_charge = { id = "rbxassetid://9113818454", volume = 0.4 },
}

return SoundDatabase
