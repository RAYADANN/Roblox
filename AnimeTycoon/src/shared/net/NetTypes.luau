--!strict
-- App HUD sync types. Zap wire format in net.zap (JSON blobs for offers/slots).

export type HudSyncPayload = {
    coins: number,
    rebirths: number,
    upgrades: { [string]: number },
    handUid: string,
    offersJson: string,
    slotsJson: string,
    inventoryJson: string,
    sellBoxCoins: number,
    sellBoxDeposits: number,
    sellCratesJson: string,
    indexFoundJson: string,
    rewardTrackStartedAt: number,
    rewardClaimedJson: string,
    tutorialCompleted: boolean,
    boostOfferEndsAt: number,
    ownsLuckyX2: boolean,
    ownsLuckyX4: boolean,
    ownsMoneyX2: boolean,
    pendingOfflineCoins: number,
}

export type BuyUpgradeResult = {
    success: boolean,
    error: string?,
    coins: number?,
}

export type ClaimTimedRewardResult = {
    success: boolean,
    error: string?,
    coins: number?,
    coinsGranted: number?,
}

export type NotifyPayload = {
    kind: string,
    payload: string,
}

export type ZapPlayerDataSync = {
    coins: number,
    rebirths: number,
    base: number,
    pad: number,
    padTier: number,
    luck: number,
    cash: number,
    time: number,
    speed: number,
    handUid: string,
    offersJson: string,
    slotsJson: string,
    inventoryJson: string,
    sellBoxCoins: number,
    sellBoxDeposits: number,
    sellCratesJson: string,
    indexFoundJson: string,
    rewardTrackStartedAt: number,
    rewardClaimedJson: string,
    tutorialCompleted: boolean,
    boostOfferEndsAt: number,
    ownsLuckyX2: boolean,
    ownsLuckyX4: boolean,
    ownsMoneyX2: boolean,
    pendingOfflineCoins: number,
}

local HttpService = game:GetService("HttpService")

local NetTypes = {}

local function encode(value: any): string
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(value)
    end)
    if ok and typeof(encoded) == "string" then
        return encoded
    end
    return "[]"
end

function NetTypes.toZapSync(payload: HudSyncPayload): ZapPlayerDataSync
    return {
        coins = payload.coins,
        rebirths = payload.rebirths,
        base = payload.upgrades.base or 0,
        pad = payload.upgrades.pad or 0,
        padTier = payload.upgrades.padTier or 0,
        luck = payload.upgrades.luck or 0,
        cash = payload.upgrades.cash or 0,
        time = payload.upgrades.time or 0,
        speed = payload.upgrades.speed or 0,
        handUid = payload.handUid,
        offersJson = payload.offersJson,
        slotsJson = payload.slotsJson,
        inventoryJson = payload.inventoryJson,
        sellBoxCoins = payload.sellBoxCoins,
        sellBoxDeposits = payload.sellBoxDeposits,
        sellCratesJson = payload.sellCratesJson,
        indexFoundJson = payload.indexFoundJson,
        rewardTrackStartedAt = payload.rewardTrackStartedAt,
        rewardClaimedJson = payload.rewardClaimedJson,
        tutorialCompleted = payload.tutorialCompleted == true,
        boostOfferEndsAt = payload.boostOfferEndsAt or 0,
        ownsLuckyX2 = payload.ownsLuckyX2 == true,
        ownsLuckyX4 = payload.ownsLuckyX4 == true,
        ownsMoneyX2 = payload.ownsMoneyX2 == true,
        pendingOfflineCoins = payload.pendingOfflineCoins or 0,
    }
end

function NetTypes.fromZapSync(value: ZapPlayerDataSync): HudSyncPayload
    return {
        coins = value.coins,
        rebirths = value.rebirths,
        upgrades = {
            base = value.base,
            pad = value.pad,
            padTier = value.padTier,
            luck = value.luck,
            cash = value.cash,
            time = value.time,
            speed = value.speed,
        },
        handUid = value.handUid,
        offersJson = value.offersJson,
        slotsJson = value.slotsJson,
        inventoryJson = value.inventoryJson,
        sellBoxCoins = value.sellBoxCoins,
        sellBoxDeposits = value.sellBoxDeposits,
        sellCratesJson = value.sellCratesJson,
        indexFoundJson = value.indexFoundJson,
        rewardTrackStartedAt = value.rewardTrackStartedAt,
        rewardClaimedJson = value.rewardClaimedJson,
        tutorialCompleted = value.tutorialCompleted == true,
        boostOfferEndsAt = value.boostOfferEndsAt or 0,
        ownsLuckyX2 = value.ownsLuckyX2 == true,
        ownsLuckyX4 = value.ownsLuckyX4 == true,
        ownsMoneyX2 = value.ownsMoneyX2 == true,
        pendingOfflineCoins = value.pendingOfflineCoins or 0,
    }
end

function NetTypes.encodeOffers(offers: { any }): string
    return encode(offers)
end

function NetTypes.encodeSlots(slots: { any }): string
    return encode(slots)
end

function NetTypes.encodeInventory(inventory: { any }): string
    return encode(inventory)
end

function NetTypes.decodeJsonArray(raw: string): { any }
    if typeof(raw) ~= "string" or raw == "" then
        return {}
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if ok and typeof(decoded) == "table" then
        return decoded :: { any }
    end
    return {}
end

-- HudPayload (typed) → wire HudSyncPayload
function NetTypes.fromHudPayload(hud: any): HudSyncPayload
    return {
        coins = hud.coins,
        rebirths = hud.rebirths,
        upgrades = hud.upgrades or {},
        handUid = hud.handUid or "",
        offersJson = NetTypes.encodeOffers(hud.offers or {}),
        slotsJson = NetTypes.encodeSlots(hud.slots or {}),
        inventoryJson = NetTypes.encodeInventory(hud.inventory or {}),
        sellBoxCoins = hud.sellBoxCoins or 0,
        sellBoxDeposits = hud.sellBoxDeposits or 0,
        sellCratesJson = NetTypes.encodeInventory(hud.sellCrates or {}),
        indexFoundJson = NetTypes.encodeInventory(hud.indexFound or {}),
        rewardTrackStartedAt = hud.rewardTrackStartedAt or 0,
        rewardClaimedJson = NetTypes.encodeInventory(hud.rewardClaimed or {}),
        tutorialCompleted = hud.tutorialCompleted == true,
        boostOfferEndsAt = hud.boostOfferEndsAt or 0,
        ownsLuckyX2 = hud.ownsLuckyX2 == true,
        ownsLuckyX4 = hud.ownsLuckyX4 == true,
        ownsMoneyX2 = hud.ownsMoneyX2 == true,
        pendingOfflineCoins = hud.pendingOfflineCoins or 0,
    }
end

return NetTypes
