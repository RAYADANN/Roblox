--!strict
local InventoryBarLogic = require("../src/shared/util/InventoryBarLogic")

return {
    ["eggIconKey: rarity map"] = function(expect)
        expect(InventoryBarLogic.eggIconKey("common")).toEqual("EggDomestic")
        expect(InventoryBarLogic.eggIconKey("rare")).toEqual("EggIce")
        expect(InventoryBarLogic.eggIconKey("unknown")).toEqual("EggDomestic")
    end,
    ["hotkeyLabel: 1..9 and 0"] = function(expect)
        expect(InventoryBarLogic.hotkeyLabel(1)).toEqual("1")
        expect(InventoryBarLogic.hotkeyLabel(9)).toEqual("9")
        expect(InventoryBarLogic.hotkeyLabel(10)).toEqual("0")
        expect(InventoryBarLogic.hotkeyLabel(11)).toEqual(nil)
    end,
    ["hotkeyKeyCodeName: One..Zero"] = function(expect)
        expect(InventoryBarLogic.hotkeyKeyCodeName(1)).toEqual("One")
        expect(InventoryBarLogic.hotkeyKeyCodeName(10)).toEqual("Zero")
        expect(InventoryBarLogic.hotkeyKeyCodeName(0)).toEqual(nil)
    end,
}
