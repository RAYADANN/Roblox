--!strict
local MoneyOfferLogic = require("../src/shared/util/MoneyOfferLogic")
local ProductIds = require("../src/shared/data/ProductIds")

return {
    ["packs: x5 / x15 / x25 of balance"] = function(expect)
        local packs = MoneyOfferLogic.packs()
        expect(#packs).toEqual(3)
        expect(packs[1].balanceMult).toEqual(5)
        expect(packs[2].balanceMult).toEqual(15)
        expect(packs[3].balanceMult).toEqual(25)
    end,
    ["packs: Creator Hub product ids"] = function(expect)
        local packs = MoneyOfferLogic.packs()
        expect(packs[1].productId).toEqual(ProductIds.CoinPackSmall)
        expect(packs[2].productId).toEqual(ProductIds.CoinPackMedium)
        expect(packs[3].productId).toEqual(ProductIds.CoinPackLarge)
        expect(ProductIds.CoinPackSmall > 0).toEqual(true)
    end,
    ["coinsForProductId scales with balance"] = function(expect)
        expect(MoneyOfferLogic.coinsForProductId(ProductIds.CoinPackSmall, 2000)).toEqual(10000)
        expect(MoneyOfferLogic.coinsForProductId(ProductIds.CoinPackMedium, 2000)).toEqual(30000)
        expect(MoneyOfferLogic.coinsForProductId(ProductIds.CoinPackLarge, 2000)).toEqual(50000)
        expect(MoneyOfferLogic.coinsForProductId(0, 100)).toEqual(nil)
    end,
    ["early balance uses floor so packs stay chunky"] = function(expect)
        -- Floor 1000 → Small/Med/Large = 5k / 15k / 25k until balance catches up.
        expect(MoneyOfferLogic.effectiveBalance(0)).toEqual(1000)
        expect(MoneyOfferLogic.effectiveBalance(50)).toEqual(1000)
        expect(MoneyOfferLogic.effectiveBalance(1000)).toEqual(1000)
        expect(MoneyOfferLogic.effectiveBalance(1001)).toEqual(1001)
        expect(MoneyOfferLogic.coinsForProductId(ProductIds.CoinPackSmall, 50)).toEqual(5000)
        expect(MoneyOfferLogic.coinsForProductId(ProductIds.CoinPackMedium, 0)).toEqual(15000)
        expect(MoneyOfferLogic.coinsForProductId(ProductIds.CoinPackLarge, 50)).toEqual(25000)
    end,
}
