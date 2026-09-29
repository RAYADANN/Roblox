--!strict
local SlotLayoutLogic = require("../src/shared/util/SlotLayoutLogic")

return {
    ["parses Floor_01 names"] = function(expect)
        expect(SlotLayoutLogic.floorIndexFromName("Floor_01")).toEqual(1)
        expect(SlotLayoutLogic.floorIndexFromName("Floor_06")).toEqual(6)
        expect(SlotLayoutLogic.floorIndexFromName("Floor1")).toEqual(1)
        expect(SlotLayoutLogic.floorIndexFromName("Dummy")).toEqual(nil)
    end,

    ["expectedSlotCount is 8x5"] = function(expect)
        expect(SlotLayoutLogic.expectedSlotCount()).toEqual(40)
    end,

    ["compareKeys floors first then X/Z"] = function(expect)
        local a = { floor = 1, x = 10, z = 0, name = "b" }
        local b = { floor = 2, x = 0, z = 0, name = "a" }
        expect(SlotLayoutLogic.compareKeys(a, b)).toEqual(true)
        expect(SlotLayoutLogic.compareKeys(b, a)).toEqual(false)

        local c = { floor = 1, x = 1, z = 5, name = "a" }
        local d = { floor = 1, x = 2, z = 0, name = "b" }
        expect(SlotLayoutLogic.compareKeys(c, d)).toEqual(true)
    end,

    ["floorFolderName pads to two digits"] = function(expect)
        expect(SlotLayoutLogic.floorFolderName(1)).toEqual("Floor_01")
        expect(SlotLayoutLogic.floorFolderName(12)).toEqual("Floor_12")
    end,
}
