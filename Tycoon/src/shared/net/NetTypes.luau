--!strict
-- App HUD types. Zap payload lives in net.zap.

export type HudSyncPayload = {
    coins: number,
    pendingCash: number,
    backpackEggs: number,
    luckyBlocks: number,
    shopQueue: number,
    processPerSec: number,
    multiplier: number,
    unitCount: number,
    emptySlots: number,
    nextUnitCost: number,
    rebirths: number,
    autoCollectEggs: boolean,
    autoCollectCash: boolean,
    doubleItems: boolean,
    indexMaxTier: number,
    productionLevel: number,
    buyCount: number,
    exclusiveOfferEndsAt: number,
    exclusiveHeartOwned: boolean,
    exclusiveRebirthOwned: boolean,
}

export type BuyUpgradeResult = {
    success: boolean,
    error: string?,
    coins: number?,
}

export type RebirthResult = {
    success: boolean,
    error: string?,
    rebirths: number?,
}

export type NotifyPayload = {
    kind: string,
    payload: string,
}

export type ZapPlayerDataSync = {
    coins: number,
    pendingCash: number,
    backpackEggs: number,
    luckyBlocks: number,
    shopQueue: number,
    processPerSec: number,
    multiplier: number,
    unitCount: number,
    emptySlots: number,
    nextUnitCost: number,
    rebirths: number,
    autoCollectEggs: boolean,
    autoCollectCash: boolean,
    doubleItems: boolean,
    indexMaxTier: number,
    productionLevel: number,
    buyCount: number,
    exclusiveOfferEndsAt: number,
    exclusiveHeartOwned: boolean,
    exclusiveRebirthOwned: boolean,
}

local NetTypes = {}

function NetTypes.toZapSync(payload: HudSyncPayload): ZapPlayerDataSync
    return {
        coins = payload.coins,
        pendingCash = payload.pendingCash,
        backpackEggs = payload.backpackEggs,
        luckyBlocks = payload.luckyBlocks,
        shopQueue = payload.shopQueue,
        processPerSec = payload.processPerSec,
        multiplier = payload.multiplier,
        unitCount = payload.unitCount,
        emptySlots = payload.emptySlots,
        nextUnitCost = payload.nextUnitCost,
        rebirths = payload.rebirths,
        autoCollectEggs = payload.autoCollectEggs,
        autoCollectCash = payload.autoCollectCash,
        doubleItems = payload.doubleItems,
        indexMaxTier = payload.indexMaxTier,
        productionLevel = payload.productionLevel,
        buyCount = payload.buyCount,
        exclusiveOfferEndsAt = payload.exclusiveOfferEndsAt,
        exclusiveHeartOwned = payload.exclusiveHeartOwned,
        exclusiveRebirthOwned = payload.exclusiveRebirthOwned,
    }
end

function NetTypes.fromZapSync(value: ZapPlayerDataSync): HudSyncPayload
    return {
        coins = value.coins,
        pendingCash = value.pendingCash,
        backpackEggs = value.backpackEggs,
        luckyBlocks = value.luckyBlocks,
        shopQueue = value.shopQueue,
        processPerSec = value.processPerSec,
        multiplier = value.multiplier,
        unitCount = value.unitCount,
        emptySlots = value.emptySlots,
        nextUnitCost = value.nextUnitCost,
        rebirths = value.rebirths,
        autoCollectEggs = value.autoCollectEggs,
        autoCollectCash = value.autoCollectCash,
        doubleItems = value.doubleItems,
        indexMaxTier = value.indexMaxTier,
        productionLevel = value.productionLevel,
        buyCount = value.buyCount,
        exclusiveOfferEndsAt = value.exclusiveOfferEndsAt,
        exclusiveHeartOwned = value.exclusiveHeartOwned,
        exclusiveRebirthOwned = value.exclusiveRebirthOwned,
    }
end

return NetTypes
