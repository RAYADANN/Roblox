--!strict
-- Player profile. Persistent farm progress only.

export type UpgradeLevels = { [string]: number }

export type PlayerData = {
    coins: number,
    pendingCash: number,
    backpackEggs: number,
    luckyBlocks: number,
    shopQueue: number,
    processLevel: number,
    productionLevel: number,
    units: { number },
    buyCount: number,
    autoCollectEggs: boolean,
    autoCollectCash: boolean,
    doubleItems: boolean,
    lastSeenAt: number,
    groupRewardAt: number,
    rebirths: number,
    -- Highest merge tier ever owned; Index unlocks persist across rebirth.
    indexMaxTier: number,
    upgrades: UpgradeLevels,
    firstSessionComplete: boolean,
    -- ProcessReceipt idempotency (purchaseId → granted).
    grantedPurchases: { [string]: boolean },
    -- Unix time when exclusive offer was first shown; 0 = not seen yet. Persists rebirth/reset.
    exclusiveOfferSeenAt: number,
    -- Heart Skin (ExclusivePink DevProduct). Persists rebirth and /reset; clear only on request.
    exclusiveHeartOwned: boolean,
    -- 1 Rebirth + Coins pack. Persists rebirth and /reset; clear only on request.
    exclusiveRebirthOwned: boolean,
}

local TEMPLATE: PlayerData = {
    coins = 50,
    pendingCash = 0,
    backpackEggs = 0,
    luckyBlocks = 0,
    shopQueue = 0,
    processLevel = 0,
    productionLevel = 0,
    units = {},
    buyCount = 0,
    autoCollectEggs = false,
    autoCollectCash = false,
    doubleItems = false,
    lastSeenAt = 0,
    groupRewardAt = 0,
    rebirths = 0,
    indexMaxTier = 0,
    upgrades = {},
    firstSessionComplete = false,
    grantedPurchases = {},
    exclusiveOfferSeenAt = 0,
    exclusiveHeartOwned = false,
    exclusiveRebirthOwned = false,
}

local function applyTemplate(data: PlayerData)
    data.coins = TEMPLATE.coins
    data.pendingCash = TEMPLATE.pendingCash
    data.backpackEggs = TEMPLATE.backpackEggs
    data.luckyBlocks = TEMPLATE.luckyBlocks
    data.shopQueue = TEMPLATE.shopQueue
    data.processLevel = TEMPLATE.processLevel
    data.productionLevel = TEMPLATE.productionLevel
    data.units = {}
    data.buyCount = TEMPLATE.buyCount
    data.autoCollectEggs = TEMPLATE.autoCollectEggs
    data.autoCollectCash = TEMPLATE.autoCollectCash
    data.doubleItems = TEMPLATE.doubleItems
    data.lastSeenAt = TEMPLATE.lastSeenAt
    data.groupRewardAt = TEMPLATE.groupRewardAt
    data.rebirths = TEMPLATE.rebirths
    data.indexMaxTier = TEMPLATE.indexMaxTier
    data.upgrades = {}
    data.firstSessionComplete = TEMPLATE.firstSessionComplete
    data.grantedPurchases = {}
    -- exclusiveOfferSeenAt + exclusiveHeartOwned + exclusiveRebirthOwned intentionally kept.
end

return {
    TEMPLATE = TEMPLATE,
    applyTemplate = applyTemplate,
}
