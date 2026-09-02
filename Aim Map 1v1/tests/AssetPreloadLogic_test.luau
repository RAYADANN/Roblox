local AssetPreloadLogic = require("@shared/util/AssetPreloadLogic")

return {
    ["isLoadableId rejects empty and zero"] = function(expect)
        expect(AssetPreloadLogic.isLoadableId("")).toEqual(false)
        expect(AssetPreloadLogic.isLoadableId("rbxassetid://0")).toEqual(false)
        expect(AssetPreloadLogic.isLoadableId("rbxassetid://123")).toEqual(true)
    end,
    ["uniqueOrdered keeps first order and dedupes"] = function(expect)
        local out = AssetPreloadLogic.uniqueOrdered({
            "rbxassetid://1",
            "rbxassetid://0",
            "rbxassetid://2",
            "rbxassetid://1",
            "",
        })
        expect(#out).toEqual(2)
        expect(out[1]).toEqual("rbxassetid://1")
        expect(out[2]).toEqual("rbxassetid://2")
    end,
    ["collectFromMap skips zero ids"] = function(expect)
        local out = AssetPreloadLogic.collectFromMap({
            a = "rbxassetid://10",
            b = "rbxassetid://0",
            c = "rbxassetid://11",
        })
        expect(#out).toEqual(2)
    end,
}
