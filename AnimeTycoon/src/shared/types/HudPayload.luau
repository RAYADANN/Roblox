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
}

export type InventoryHud = {
    uid: string,
    displayName: string,
    rarity: string,
    boxModelName: string,
    mutationLabel: string,
}

export type HudPayload = {
    coins: number,
    rebirths: number,
    upgrades: { [string]: number },
    handUid: string?,
    offers: { OfferHud },
    slots: { SlotHud },
    inventory: { InventoryHud },
}

return {}
