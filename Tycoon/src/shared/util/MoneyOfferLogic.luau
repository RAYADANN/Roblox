--!strict
-- HUD coin packs: DevProduct id → grant = max(balance, floor) × mult. CI-tested (Lune).

local ProductIds
local Constants
if script and script.Parent then
    ProductIds = require(script.Parent.Parent.data.ProductIds)
    Constants = require(script.Parent.Parent.data.Constants)
else
    ProductIds = require("../data/ProductIds")
    Constants = require("../data/Constants")
end

export type Pack = {
    productId: number,
    -- Grant = max(balance, MONEY_OFFER_BALANCE_FLOOR) × balanceMult.
    balanceMult: number,
}

local MoneyOfferLogic = {}

-- Top → bottom on the HUD stack. Matches Small / Medium / Large in Creator Hub.
local PACKS: { Pack } = {
    { productId = ProductIds.CoinPackSmall, balanceMult = 5 },
    { productId = ProductIds.CoinPackMedium, balanceMult = 15 },
    { productId = ProductIds.CoinPackLarge, balanceMult = 25 },
}

function MoneyOfferLogic.packs(): { Pack }
    return PACKS
end

function MoneyOfferLogic.packForProductId(productId: number): Pack?
    if productId ~= productId or productId <= 0 then
        return nil
    end
    for i = 1, #PACKS do
        if PACKS[i].productId == productId then
            return PACKS[i]
        end
    end
    return nil
end

--- Effective balance used for pack grants (floor keeps early Robux packs chunky).
function MoneyOfferLogic.effectiveBalance(balance: number): number
    local floored = math.max(math.floor(balance), 0)
    return math.max(floored, Constants.MONEY_OFFER_BALANCE_FLOOR)
end

--- Cash granted for this pack at the player's current balance.
function MoneyOfferLogic.coinsForProductId(productId: number, balance: number): number?
    local pack = MoneyOfferLogic.packForProductId(productId)
    if pack == nil then
        return nil
    end
    return math.floor(MoneyOfferLogic.effectiveBalance(balance) * pack.balanceMult)
end

function MoneyOfferLogic.isPackProduct(productId: number): boolean
    return MoneyOfferLogic.packForProductId(productId) ~= nil
end

return MoneyOfferLogic
