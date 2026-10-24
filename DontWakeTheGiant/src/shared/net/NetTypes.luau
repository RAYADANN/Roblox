--!strict
-- Типы HUD-синхронизации (приложение). Zap payload — в net.zap.

export type HudSyncPayload = {
    coins: number,
    incomePerSec: number,
}

export type NotifyPayload = {
    kind: string,
    payload: string,
}

return {}
