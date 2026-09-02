--!strict
-- Проекция профиля для клиента. НЕ весь PlayerData — только то, что нужно UI.

export type HudPayload = {
    wins: number,
    losses: number,
    equippedSkinId: string,
    lookSensitivity: number,
    crosshairId: string,
    ownedSkinIds: { string },
}

return {}
