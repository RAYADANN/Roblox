--!strict
-- Звуковые события. Combat + ui_click = Workspace.Sounds templates; demo vfx = 0 until real assets.

export type SoundEntry = {
    id: string,
    volume: number,
}

local SoundDatabase: { [string]: SoundEntry } = {
    ui_click = { id = "rbxassetid://104184340183231", volume = 0.5 },
    ui_confirm = { id = "rbxassetid://0", volume = 0.6 },
    sell_success = { id = "rbxassetid://0", volume = 0.7 },
    sell_fail = { id = "rbxassetid://0", volume = 0.5 },

    -- Combat (Workspace templates)
    usp_fire = { id = "rbxassetid://4108910200", volume = 0.5 },
    hit_head = { id = "rbxassetid://133002449941130", volume = 0.55 },
    hit_body = { id = "rbxassetid://139520673393967", volume = 0.5 },
    kill = { id = "rbxassetid://7968068093", volume = 0.9 },
    dead = { id = "rbxassetid://5909769329", volume = 0.5 },
    footstep = { id = "rbxassetid://87061775498714", volume = 0.5 },

    -- Starter demo VFX — disabled (old catalog ids were not Audio assets).
    vfx_impact = { id = "rbxassetid://0", volume = 0.55 },
    vfx_crit = { id = "rbxassetid://0", volume = 0.7 },
    vfx_cast = { id = "rbxassetid://0", volume = 0.5 },
    vfx_whoosh = { id = "rbxassetid://0", volume = 0.4 },
    vfx_spark = { id = "rbxassetid://0", volume = 0.35 },
    vfx_heal = { id = "rbxassetid://0", volume = 0.45 },
    vfx_slam = { id = "rbxassetid://0", volume = 0.65 },
    vfx_charge = { id = "rbxassetid://0", volume = 0.4 },
}

return SoundDatabase
