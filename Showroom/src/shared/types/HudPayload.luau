--!strict
-- HUD projection for Showroom. Pure.

export type OfferHud = {
    uid: string,
    templateId: string,
    rarity: string,
    sizeId: string,
    displayName: string,
    baseIncome: number,
    buyPrice: number,
    mutationLabel: string,
}

export type SlotHud = {
    occupied: boolean,
    uid: string?,
    rarity: string?,
    displayName: string?,
    progress: number,
    incomeRate: number,
    evolved: boolean,
    mutated: boolean,
    mutationLabel: string,
    sellPrice: number,
}

export type InvHud = {
    uid: string,
    rarity: string,
    displayName: string,
    baseIncome: number,
}

export type HudPayload = {
    coins: number,
    plotId: number,
    favoriteBank: number,
    offers: { OfferHud },
    slots: { SlotHud },
    inventory: { InvHud },
    handUid: string?,
    handName: string?,
}

return {}
