--!strict
-- Exclusive HUD offers (spinning bg + product slots). Pure data for UI.

export type TitleStyle = "pink" | "orange"

export type Offer = {
    id: string,
    -- Display name above pedestal art.
    title: string,
    titleStyle: TitleStyle,
    -- IconCatalog / GameAssets name for pedestal art (empty = reserved slot).
    imageCatalog: string,
    gameAssetName: string,
    robux: number,
    productKey: string,
}

local OFFERS: { Offer } = {
    {
        id = "pink_platform",
        title = "Heart Skin",
        titleStyle = "pink",
        imageCatalog = "ExclusivePlatformPink",
        gameAssetName = "ExclusivePlatformPink",
        robux = 99,
        productKey = "ExclusivePink",
    },
    {
        id = "rebirth_coins",
        title = "1 Rebirth + Coins",
        titleStyle = "orange",
        imageCatalog = "ExclusiveRebirthCoins",
        gameAssetName = "ExclusiveRebirthCoins",
        robux = 25,
        productKey = "ExclusiveRebirthCoins",
    },
}

local ExclusiveOffers = {}

function ExclusiveOffers.all(): { Offer }
    return OFFERS
end

function ExclusiveOffers.offerForId(offerId: string): Offer?
    for _, offer in OFFERS do
        if offer.id == offerId then
            return offer
        end
    end
    return nil
end

return ExclusiveOffers
