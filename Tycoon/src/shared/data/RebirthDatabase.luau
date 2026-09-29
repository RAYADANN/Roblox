--!strict
-- Cash-gated rebirth tiers (Chicken Farm-style). Numbers live here, not in Constants.

export type Tier = {
    cashRequired: number,
    cashMultiplier: number,
}

-- Index = rebirth you are taking (1 = first). cashMultiplier is absolute income after that rebirth.
-- First row matches the Rebirth mockup: 1000 cash → X2 Coins.
local Tiers: { Tier } = {
    { cashRequired = 1_000, cashMultiplier = 2 },
    { cashRequired = 25_000, cashMultiplier = 5 },
    { cashRequired = 500_000, cashMultiplier = 10 },
    { cashRequired = 10_000_000, cashMultiplier = 25 },
    { cashRequired = 250_000_000, cashMultiplier = 60 },
    { cashRequired = 5_000_000_000, cashMultiplier = 125 },
    { cashRequired = 150_000_000_000, cashMultiplier = 350 },
    { cashRequired = 5_000_000_000_000, cashMultiplier = 900 },
    { cashRequired = 150_000_000_000_000, cashMultiplier = 2_500 },
    { cashRequired = 5_000_000_000_000_000, cashMultiplier = 7_000 },
    { cashRequired = 200_000_000_000_000_000, cashMultiplier = 20_000 },
    { cashRequired = 7_000_000_000_000_000_000, cashMultiplier = 50_000 },
}

return {
    Tiers = Tiers,
    OVERFLOW_COST_MULT = 50,
    OVERFLOW_CASH_MULT = 3,
}
