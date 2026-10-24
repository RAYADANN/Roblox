--!strict
local FormatNumber = require("../src/shared/util/FormatNumber")

return {
    ["short: меньше тысячи без суффикса"] = function(expect)
        expect(FormatNumber.short(0)).toEqual("0")
        expect(FormatNumber.short(320)).toEqual("320")
        expect(FormatNumber.short(999)).toEqual("999")
    end,
    ["short: три значащие цифры"] = function(expect)
        expect(FormatNumber.short(1250000)).toEqual("1.25M")
        expect(FormatNumber.short(45.3e9)).toEqual("45.3B")
        expect(FormatNumber.short(812e12)).toEqual("812T")
    end,
    ["short: лишние нули отбрасываются"] = function(expect)
        expect(FormatNumber.short(1500)).toEqual("1.5K")
        expect(FormatNumber.short(25000)).toEqual("25K")
        expect(FormatNumber.short(50e9)).toEqual("50B")
    end,
    ["short: без округления вверх через порядок"] = function(expect)
        expect(FormatNumber.short(999999)).toEqual("999K")
        expect(FormatNumber.short(1e15)).toEqual("1Qa")
        expect(FormatNumber.short(2.5e18)).toEqual("2.5Qi")
    end,
    ["short: отрицательные"] = function(expect)
        expect(FormatNumber.short(-15000)).toEqual("-15K")
    end,
}
