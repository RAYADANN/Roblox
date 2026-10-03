--!strict
-- HUD projection for client. Not full PlayerData.

export type OfferHud = {
    uid: string,
    templateId: string,
    boxModelName: string,
    rarity: string,
    heroId: string,
    displayName: string,
    baseIncome: number,
    buyPrice: number,
    mutationLabel: string,
}

export type SlotHud = {
    uid: string,
    templateId: string,
    boxModelName: string,
    rarity: string,
    heroId: string,
    displayName: string,
    unpackProgress: number,
    unpacked: boolean,
    mutationLabel: string,
    incomeRate: number,
    slotIndex: number,
    --- 1 until the container is opened.
    level: number,
    --- Coins to reach the next level. 0 when sealed or maxed.
    levelCost: number,
}

export type InventoryHud = {
    uid: string,
    displayName: string,
    rarity: string,
    boxModelName: string,
    mutationLabel: string,
    --- Hand / backpack visual.
    heroId: string,
    templateId: string,
    unpacked: boolean,
    mutations: { string },
}

export type SellCrateHud = {
    uid: string,
    coins: number,
    depositCount: number,
}

export type HudPayload = {
    coins: number,
    rebirths: number,
    upgrades: { [string]: number },
    handUid: string?,
    offers: { OfferHud },
    slots: { SlotHud },
    inventory: { InventoryHud },
    sellBoxCoins: number,
    sellBoxDeposits: number,
    sellCrates: { SellCrateHud },
    --- Index discovery keys (heroId or heroId:mutationId).
    indexFound: { string },
    rewardTrackStartedAt: number,
    rewardClaimed: { string },
    tutorialCompleted: boolean,
    --- Unix end of boost-offer sale window (0 = not started / full duration client-side).
    boostOfferEndsAt: number,
    ownsLuckyX2: boolean,
    ownsLuckyX4: boolean,
    ownsMoneyX2: boolean,
    --- Pending offline claim (0 = hide window).
    pendingOfflineCoins: number,
}

return {}
