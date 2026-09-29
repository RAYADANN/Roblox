--!strict
local PadLogic = require("../src/shared/util/PadLogic")

return {
    ["buyAffordable respects coins and slots"] = function(expect)
        expect(PadLogic.buyAffordable({}, 1, 1, 0, 6)).toEqual(true)
        expect(PadLogic.buyAffordable({}, 1, 0, 0, 6)).toEqual(false)
        -- Full board with no mergeable triple cannot take another buy.
        expect(PadLogic.buyAffordable({ 1, 2, 3, 4, 5, 6 }, 1, 999, 0, 6)).toEqual(false)
    end,

    ["buyAffordable allows overflow when auto-merge fits"] = function(expect)
        expect(PadLogic.buyAffordable({}, 100, 99999, 0, 40)).toEqual(true)
    end,

    ["buyCanPay is money-only"] = function(expect)
        expect(PadLogic.buyCanPay(20, 0, 1)).toEqual(true)
        expect(PadLogic.buyCanPay(0, 0, 1)).toEqual(false)
    end,

    ["mergeReady needs three matching"] = function(expect)
        expect(PadLogic.mergeReady({ 1, 1 })).toEqual(false)
        expect(PadLogic.mergeReady({ 1, 1, 1 })).toEqual(true)
    end,

    ["upgradeAffordable compares cost"] = function(expect)
        expect(PadLogic.upgradeAffordable(100, 75)).toEqual(true)
        expect(PadLogic.upgradeAffordable(50, 75)).toEqual(false)
    end,
}
