--!strict
local FavoriteLogic = require("../src/shared/util/FavoriteLogic")

return {
    ["firstEmpty: finds hole"] = function(expect)
        local slots: { any? } = { nil, {}, nil, nil, nil }
        expect(FavoriteLogic.firstEmpty(slots)).toEqual(1)
        slots[1] = {}
        expect(FavoriteLogic.firstEmpty(slots)).toEqual(3)
        slots[3] = {}
        expect(FavoriteLogic.firstEmpty(slots)).toEqual(4)
        slots[4] = {}
        slots[5] = {}
        expect(FavoriteLogic.firstEmpty(slots) == nil).toBeTruthy()
    end,
    ["isValidSlot"] = function(expect)
        expect(FavoriteLogic.isValidSlot(1)).toBeTruthy()
        expect(FavoriteLogic.isValidSlot(5)).toBeTruthy()
        expect(FavoriteLogic.isValidSlot(0)).toBeFalsy()
        expect(FavoriteLogic.isValidSlot(6)).toBeFalsy()
    end,
}
