--!strict
-- Product / Gamepass IDs. Creator Hub is the source; 0 = not configured.

local ProductIds = {
    -- gamepasses (Creator Hub)
    X2Items = 1982708336,
    AutoCollectItems = 1983260332,
    AutoCollectCash = 1982252321,
    VIP = 0,
    -- HUD coin packs (Small / Medium / Large) — max(balance, floor) × 5 / 15 / 25
    -- ProductId from Creator Hub / GetDeveloperProductsAsync (not Asset/DeveloperProductId).
    CoinPackSmall = 3712983741,
    CoinPackMedium = 3712983777,
    CoinPackLarge = 3712983805,
    -- Finish Now pad — flush shop queue (20 R$)
    FinishNow = 3712997444,
    -- Exclusive pink platform offer (Heart Skin) — Creator Hub DevProduct.
    ExclusivePink = 3713062105,
    -- Exclusive 1 Rebirth + Coins pack (Creator Hub DevProduct).
    ExclusiveRebirthCoins = 3713065486,
    -- Skip rebirth requirement (Robux). 0 = not configured → UI disables Skip.
    SkipRebirth = 0,
}

return ProductIds
