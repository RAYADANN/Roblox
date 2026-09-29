--!strict
local FinishNowLogic = require("../src/shared/util/FinishNowLogic")
local ProductIds = require("../src/shared/data/ProductIds")

return {
    ["productId matches Creator Hub Finish Now"] = function(expect)
        expect(FinishNowLogic.productId()).toEqual(3712997444)
        expect(FinishNowLogic.productId()).toEqual(ProductIds.FinishNow)
        expect(ProductIds.FinishNow > 0).toEqual(true)
    end,
    ["robux price is 20"] = function(expect)
        expect(FinishNowLogic.ROBUX).toEqual(20)
    end,
    ["isProduct roundtrip"] = function(expect)
        expect(FinishNowLogic.isProduct(ProductIds.FinishNow)).toEqual(true)
        expect(FinishNowLogic.isProduct(0)).toEqual(false)
        expect(FinishNowLogic.isProduct(ProductIds.CoinPackSmall)).toEqual(false)
    end,
}
