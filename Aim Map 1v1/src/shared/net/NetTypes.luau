--!strict
-- Типы HUD / матч синхронизации (приложение). Zap payload — в net.zap.

export type HudSyncPayload = {
    wins: number,
    losses: number,
    equippedSkinId: string,
    lookSensitivity: number,
    crosshairId: string,
    ownedSkinIds: { string },
}

export type MatchSyncPayload = {
    matchId: string,
    phase: string,
    firstTo: number,
    youScore: number,
    oppScore: number,
    oppName: string,
    canRematch: boolean,
    youReadyRematch: boolean,
    oppReadyRematch: boolean,
    visibleSkinId: string,
    oppVisibleSkinId: string,
}

export type FireWeaponResult = {
    success: boolean,
    hit: boolean,
    killed: boolean,
    error: string?,
    damage: number?,
    hitPos: Vector3?,
    headshot: boolean?,
    traceEnd: Vector3?,
}

export type RematchResult = {
    success: boolean,
    error: string?,
}

export type StartBotMatchResult = {
    success: boolean,
    error: string?,
}

export type SetSensitivityResult = {
    success: boolean,
    error: string?,
    lookSensitivity: number?,
}

export type SetCrosshairResult = {
    success: boolean,
    error: string?,
    crosshairId: string?,
}

export type SetEquippedSkinResult = {
    success: boolean,
    error: string?,
    equippedSkinId: string?,
}

export type NotifyPayload = {
    kind: string,
    payload: string,
}

export type OfferSkinEquipPayload = {
    skinId: string,
    owned: boolean,
}

export type ZapPlayerDataSync = {
    wins: number,
    losses: number,
    equippedSkinId: string,
    lookSensitivity: number,
    crosshairId: string,
    ownedSkinIds: { string },
}

export type ZapMatchStateSync = {
    matchId: string,
    phase: string,
    firstTo: number,
    youScore: number,
    oppScore: number,
    oppName: string,
    canRematch: boolean,
    youReadyRematch: boolean,
    oppReadyRematch: boolean,
    visibleSkinId: string,
    oppVisibleSkinId: string,
}

local NetTypes = {}

function NetTypes.toZapSync(payload: HudSyncPayload): ZapPlayerDataSync
    return {
        wins = payload.wins,
        losses = payload.losses,
        equippedSkinId = payload.equippedSkinId,
        lookSensitivity = payload.lookSensitivity,
        crosshairId = payload.crosshairId,
        ownedSkinIds = payload.ownedSkinIds,
    }
end

function NetTypes.fromZapSync(value: ZapPlayerDataSync): HudSyncPayload
    return {
        wins = value.wins,
        losses = value.losses,
        equippedSkinId = value.equippedSkinId,
        lookSensitivity = value.lookSensitivity,
        crosshairId = value.crosshairId,
        ownedSkinIds = value.ownedSkinIds,
    }
end

function NetTypes.toZapMatch(payload: MatchSyncPayload): ZapMatchStateSync
    return payload
end

function NetTypes.fromZapMatch(value: ZapMatchStateSync): MatchSyncPayload
    return value
end

return NetTypes
