--!strict
-- Схема профиля игрока. Единственный источник правды для персистентных данных.

export type PlayerData = {
    wins: number,
    losses: number,
    ownedSkins: { [string]: boolean },
    equippedSkinId: string,
    lookSensitivity: number,
    crosshairId: string,
    firstSessionComplete: boolean,
}

local TEMPLATE: PlayerData = {
    wins = 0,
    losses = 0,
    ownedSkins = { usp_default = true },
    equippedSkinId = "usp_default",
    lookSensitivity = 1,
    crosshairId = "classic",
    firstSessionComplete = false,
}

return {
    TEMPLATE = TEMPLATE,
}
