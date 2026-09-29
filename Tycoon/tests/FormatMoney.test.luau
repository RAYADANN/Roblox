--!strict
local FormatMoney = require("../src/shared/util/FormatMoney")

return {
    ["short keeps small numbers"] = function(expect)
        expect(FormatMoney.short(1)).toEqual("1")
        expect(FormatMoney.short(999)).toEqual("999")
    end,

    ["short uses K M B T without trailing .0"] = function(expect)
        expect(FormatMoney.short(1000)).toEqual("1K")
        expect(FormatMoney.short(10_000)).toEqual("10K")
        expect(FormatMoney.short(1500)).toEqual("1.5K")
        expect(FormatMoney.short(100_000_000)).toEqual("100M")
        expect(FormatMoney.short(1_000_000_000)).toEqual("1B")
        expect(FormatMoney.short(2_500_000_000_000)).toEqual("2.5T")
    end,

    ["comma aliases short for UI"] = function(expect)
        expect(FormatMoney.comma(1000)).toEqual("1K")
        expect(FormatMoney.comma(1234567)).toEqual("1.2M")
    end,

    ["rate keeps one decimal under 1k"] = function(expect)
        expect(FormatMoney.rate(2.5)).toEqual("2.5")
        expect(FormatMoney.rate(25)).toEqual("25")
        expect(FormatMoney.rate(0.2)).toEqual("0.2")
        expect(FormatMoney.rate(2500)).toEqual("2.5K")
    end,
}
