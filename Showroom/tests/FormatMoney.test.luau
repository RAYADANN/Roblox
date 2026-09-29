--!strict
local FormatMoney = require("../src/shared/util/FormatMoney")

return {
    ["short keeps small numbers"] = function(expect)
        expect(FormatMoney.short(1)).toEqual("1")
        expect(FormatMoney.short(999)).toEqual("999")
    end,

    ["comma matches HUD $1,000"] = function(expect)
        expect(FormatMoney.comma(1)).toEqual("1")
        expect(FormatMoney.comma(1000)).toEqual("1,000")
        expect(FormatMoney.comma(1234567)).toEqual("1,234,567")
    end,
}
