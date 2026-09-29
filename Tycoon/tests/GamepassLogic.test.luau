--!strict
local GamepassLogic = require("../src/shared/util/GamepassLogic")
local ProductIds = require("../src/shared/data/ProductIds")

return {
    ["passes: three Creator Hub gamepasses"] = function(expect)
        expect(#GamepassLogic.passes()).toEqual(3)
        expect(ProductIds.X2Items).toEqual(1982708336)
        expect(ProductIds.AutoCollectItems > 0).toEqual(true)
        expect(ProductIds.AutoCollectCash > 0).toEqual(true)
    end,
    ["passForField maps pads to Hub ids"] = function(expect)
        local x2 = GamepassLogic.passForField("doubleItems")
        local items = GamepassLogic.passForField("autoCollectEggs")
        local cash = GamepassLogic.passForField("autoCollectCash")
        expect(x2 ~= nil and x2.gamepassId == ProductIds.X2Items).toEqual(true)
        expect(items ~= nil and items.gamepassId == ProductIds.AutoCollectItems).toEqual(true)
        expect(cash ~= nil and cash.gamepassId == ProductIds.AutoCollectCash).toEqual(true)
        expect(x2 ~= nil and x2.robux == 149).toEqual(true)
    end,
    ["fieldForAction matches PadIds"] = function(expect)
        expect(GamepassLogic.fieldForAction("DoubleItems")).toEqual("doubleItems")
        expect(GamepassLogic.fieldForAction("AutoCollectEggs")).toEqual("autoCollectEggs")
        expect(GamepassLogic.fieldForAction("AutoCollectCash")).toEqual("autoCollectCash")
        expect(GamepassLogic.fieldForAction("Buy1")).toEqual(nil)
    end,
    ["passForGamepassId roundtrip"] = function(expect)
        local pass = GamepassLogic.passForGamepassId(ProductIds.X2Items)
        expect(pass ~= nil and pass.field == "doubleItems").toEqual(true)
        expect(GamepassLogic.passForGamepassId(0)).toEqual(nil)
    end,
}
