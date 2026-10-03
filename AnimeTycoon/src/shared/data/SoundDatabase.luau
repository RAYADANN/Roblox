--!strict
-- Sound events. Ids mirrored from Tycoon Workspace templates / SoundDatabase.

export type SoundCategory = "sfx" | "ui" | "music"

export type SoundEntry = {
    id: string,
    volume: number,
    loop: boolean?,
    category: SoundCategory?,
}

local SoundDatabase: { [string]: SoundEntry } = {
    -- Tycoon Workspace.Background
    bg_music = {
        id = "rbxassetid://1840383905",
        volume = 0.8,
        loop = true,
        category = "music",
    },

    -- Tycoon Workspace.ButtonClickPhysic — HUD / buttons
    ui_click = { id = "rbxassetid://8755541422", volume = 0.5, category = "ui" },
    ui_confirm = { id = "rbxassetid://8755541422", volume = 0.55, category = "ui" },

    -- Tycoon SellItems / Coin Collect
    sell_success = { id = "rbxassetid://136993031050456", volume = 0.65 },
    coin_collect = { id = "rbxassetid://80977935658780", volume = 0.65 },

    sell_fail = { id = "rbxassetid://0", volume = 0.5 },

    -- Workspace.confetti-pop-sound — Robux purchase celebrate
    confetti_pop = { id = "rbxassetid://76586276648178", volume = 0.55, category = "ui" },

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
