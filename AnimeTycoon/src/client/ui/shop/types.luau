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

export type GamepassOffer = {
    id: string,
    title: string,
    accent: Color3,
    badge: string?,
    image: string?,
    perks: { GamepassPerk },
    offer: RobuxOffer,
}

return {}
