--!strict
local CollectCashFxLogic = require("../src/shared/util/CollectCashFxLogic")

return {
    ["coinCount scales with payout"] = function(expect)
        expect(CollectCashFxLogic.coinCount(0)).toEqual(0)
        expect(CollectCashFxLogic.coinCount(1)).toEqual(5)
        local big = CollectCashFxLogic.coinCount(1_000_000)
        expect(big <= 16).toEqual(true)
        expect(big >= 5).toEqual(true)
    end,
}
