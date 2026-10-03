--!strict

export type RobuxOffer = {
    productId: string,
    price: number,
    originalPrice: number?,
    label: string?,
}

export type DropPreview = {
    id: string,
    name: string,
    valueText: string,
    chanceText: string,
    rarity: "common" | "rare" | "legendary" | "limited",
    image: string?,
}

export type PackOffer = {
    id: string,
    title: string,
    subtitle: string?,
    badge: string?,
    heroImage: string?,
    drops: { DropPreview },
    buys: { RobuxOffer },
}

export type BoostOffer = {
    id: string,
    title: string,
    description: string,
    accent: Color3?,
    multiplierText: string?,
    image: string?,
    iconImage: string?,
    buyVariant: string?,
    --- Already owned (HUD Lucky/Money passes) → show Owned, no buy.
    owned: boolean?,
    offer: RobuxOffer,
}

export type CashOffer = {
    id: string,
    title: string,
    valueText: string,
    image: string?,
    iconImage: string?,
    offer: RobuxOffer,
}

export type GamepassPerk = {
    icon: string?,
    text: string,
}

--- Wide SpecialPack card (StarterGui GamePass) and legacy perk rows share this type.
export type GamepassOffer = {
    id: string,
    title: string,
    description: string?,
    accent: Color3?,
    badge: string?,
    image: string?,
    icons: { string }?,
    perks: { GamepassPerk }?,
    buyVariant: string?,
    offer: RobuxOffer,
}

return {}
