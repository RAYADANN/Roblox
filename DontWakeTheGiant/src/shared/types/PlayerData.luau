--!strict
-- Схема профиля игрока (GDD 12.2). Единственный источник правды для персистентных данных.
-- Этап 1 использует только Coins / TotalEarned; остальное наполняется на этапе 2.

export type PedestalEntry = { ItemId: string, Mutation: string? }

export type PlayerData = {
    Version: number,
    Coins: number,
    TotalEarned: number,
    SlotsUnlocked: number,
    Pedestals: { [string]: PedestalEntry },
    Upgrades: { QuietBoots: number, StrongBack: number, BetterLock: number },
    Index: { [string]: { Found: boolean, Mutations: { [string]: boolean } } },
    IndexRewards: { [string]: boolean },
    PlaytimeSeconds: number,
    ShieldSecondsLeft: number,
    Tutorial: { [string]: boolean },
    DailyStreak: number,
    LastDailyClaim: number,
    LastLogout: number,
    Limited: { Nightcap: boolean },
}

local TEMPLATE: PlayerData = {
    Version = 1,
    Coins = 0,
    TotalEarned = 0,
    SlotsUnlocked = 6,
    Pedestals = {},
    Upgrades = { QuietBoots = 0, StrongBack = 0, BetterLock = 0 },
    Index = {},
    IndexRewards = {},
    PlaytimeSeconds = 0,
    ShieldSecondsLeft = 480,
    Tutorial = {},
    DailyStreak = 0,
    LastDailyClaim = 0,
    LastLogout = 0,
    Limited = { Nightcap = false },
}

return {
    TEMPLATE = TEMPLATE,
}
