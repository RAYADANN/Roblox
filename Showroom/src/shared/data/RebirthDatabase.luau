--!strict
-- Rebirth perk cards shown in the modal (UI catalog). Numbers for cost live in Constants.

export type Perk = {
    id: string,
    title: string,
    iconKey: string,
    cardBgKey: string,
    -- When true, title is replaced with RebirthLogic.coinRewardLabel(rebirths).
    dynamicCoinTitle: boolean?,
}

local Perks: { Perk } = {
    {
        id = "new_egg",
        title = "New Egg",
        iconKey = "NewEgg",
        cardBgKey = "CardIce",
    },
    {
        id = "new_mutation",
        title = "New Mutation",
        iconKey = "NewMutation",
        cardBgKey = "CardFire",
    },
    {
        id = "x_coins",
        title = "X2 Coins",
        iconKey = "XCoins",
        cardBgKey = "CardStandart",
        dynamicCoinTitle = true,
    },
    {
        id = "incubator",
        title = "+1 Incubator",
        iconKey = "AddIncubator",
        cardBgKey = "CardGreen",
    },
    {
        id = "favorite",
        title = "+1 Favorite Place",
        iconKey = "FavoritePlace",
        cardBgKey = "CardIce",
    },
}

return {
    Perks = Perks,
}
