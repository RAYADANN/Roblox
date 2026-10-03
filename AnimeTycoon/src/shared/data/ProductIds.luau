--!strict
-- Creator Hub ids. GamePasses ≠ DevProducts — see MonetizationManager / BoostOfferManager.

local ProductIds = {
    -- GamePasses
    VIP = 0, -- not created yet
    MegaPack = 2005550308,
    LuckyX2 = 2006822300,
    LuckyX4 = 2005268309,
    MoneyX2Gold = 2006498308,

    -- DevProducts
    CoinPackSmall = 3715916631, -- Cash Small 9 R$
    CoinPackMedium = 3715916669, -- Cash Medium 24 R$
    CoinPackBig = 3715916718, -- Cash Big 79 R$
    SkipUnpack = 3715916513, -- Skip Open 49 R$
    LimitedRobStand1 = 3715916344, -- Orcalero Orcala 499 R$
    LimitedRobStand2 = 3715916253, -- La Vacca Saturno Saturnita 1299 R$
    LimitedRobStand3 = 3715916151, -- Dragon Cannelonni 3999 R$
    OfflineDouble = 3715918045, -- Offline Double 49 R$
    SkipAllRewards = 3715918964, -- Skip All (Rewards) 119 R$

    -- Upgrade Robux levels (DevProducts)
    UpgradeBase = 3715919976, -- Base Expansion 99 R$
    UpgradePad = 3715920037, -- Pad Unlock 49 R$
    UpgradePadTier = 3715920091, -- Pad Upgrade 79 R$
    UpgradeLuck = 3715920159, -- Luck Boost 29 R$
    UpgradeCash = 3715920209, -- Cash Boost 29 R$
    UpgradeTime = 3715920286, -- Time Boost 19 R$
    UpgradeSpeed = 3715920330, -- Speed Boost 19 R$
}

--- Display price on ProximityPrompt (Robux). Must match Creator Hub product.
ProductIds.SkipUnpackRobuxPrice = 49

--- HUD sale display (strikethrough was). Real charge = Creator Hub product price.
ProductIds.BoostOfferRobux = 10
ProductIds.BoostOfferRobuxWas = 49

--- Offline earnings Double button (display). Must match Creator Hub product.
ProductIds.OfflineDoubleRobuxPrice = 49

--- Shop Mega Pack display price (GamePass).
ProductIds.MegaPackRobuxPrice = 4500

--- Timed Rewards Skip All (display). Must match Creator Hub product.
ProductIds.SkipAllRewardsRobuxPrice = 119

--- Soft-currency grants for cash DevProducts.
ProductIds.CoinPackSmallCoins = 50_000
ProductIds.CoinPackMediumCoins = 200_000
ProductIds.CoinPackBigCoins = 1_000_000

return ProductIds
