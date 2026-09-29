--!strict
-- Shop catalog (Showroom Icons: coin packs + Luck/Gold banners).

export type LayoutKind = "pack" | "banner"
export type HeroKind = "coin" | "luck" | "none"

export type ProductDef = {
    id: string,
    title: string,
    description: string?,
    kind: LayoutKind,
    priceRobux: number,
    featured: boolean,
    plateKey: string,
    heroKey: string?,
    heroKind: HeroKind,
    nativeWidth: number,
    nativeHeight: number,
    -- Base coin grant at early game; actual grant scales with ShopLogic.progressScale.
    baseGrant: number?,
}

local PACK_ASPECT_W = 267
local PACK_ASPECT_H = 323

local PRODUCTS: { ProductDef } = {
    {
        id = "luck",
        title = "x2 Luck",
        description = "Higher chance of rare eggs and rare mutations.",
        kind = "banner",
        priceRobux = 199,
        featured = true,
        plateKey = "ShopLuck",
        heroKey = "LuckIcon",
        heroKind = "luck",
        nativeWidth = 1121,
        nativeHeight = 260,
    },
    {
        id = "gold_boost",
        title = "x2 Gold",
        description = "Double coin income",
        kind = "banner",
        priceRobux = 149,
        featured = false,
        plateKey = "ShopGold",
        heroKey = "ShopCoin",
        heroKind = "coin",
        nativeWidth = 1121,
        nativeHeight = 260,
    },
    {
        id = "coins_small",
        title = "Coins",
        kind = "pack",
        priceRobux = 49,
        featured = false,
        plateKey = "CardStandart",
        heroKey = "CoinsSmall",
        heroKind = "coin",
        nativeWidth = PACK_ASPECT_W,
        nativeHeight = PACK_ASPECT_H,
        baseGrant = 500,
    },
    {
        id = "coins_medium",
        title = "Coins",
        kind = "pack",
        priceRobux = 99,
        featured = false,
        plateKey = "CardStandart",
        heroKey = "CoinsMedium",
        heroKind = "coin",
        nativeWidth = PACK_ASPECT_W,
        nativeHeight = PACK_ASPECT_H,
        baseGrant = 1500,
    },
    {
        id = "coins_large",
        title = "Coins",
        kind = "pack",
        priceRobux = 199,
        featured = true,
        plateKey = "CardStandart",
        heroKey = "CoinsLarge",
        heroKind = "coin",
        nativeWidth = PACK_ASPECT_W,
        nativeHeight = PACK_ASPECT_H,
        baseGrant = 4000,
    },
    {
        id = "coins_pouch",
        title = "Coins",
        kind = "pack",
        priceRobux = 399,
        featured = false,
        plateKey = "CardStandart",
        heroKey = "CoinsPouch",
        heroKind = "coin",
        nativeWidth = PACK_ASPECT_W,
        nativeHeight = PACK_ASPECT_H,
        baseGrant = 10000,
    },
    {
        id = "coins_chest",
        title = "Coins",
        kind = "pack",
        priceRobux = 799,
        featured = true,
        plateKey = "CardStandart",
        heroKey = "CoinsChest",
        heroKind = "coin",
        nativeWidth = PACK_ASPECT_W,
        nativeHeight = PACK_ASPECT_H,
        baseGrant = 25000,
    },
}

local byId: { [string]: ProductDef } = {}
for _, p in PRODUCTS do
    byId[p.id] = p
end

local ShopDatabase = {
    PRODUCTS = PRODUCTS,
    byId = byId,
}

function ShopDatabase.get(id: string): ProductDef?
    return byId[id]
end

function ShopDatabase.aspect(def: ProductDef): number
    return def.nativeWidth / def.nativeHeight
end

return ShopDatabase
