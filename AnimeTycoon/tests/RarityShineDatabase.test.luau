--!strict

local RarityShineDatabase = require("../src/shared/data/RarityShineDatabase")

return {
    ["locked variants match picks"] = function(expect)
        expect(RarityShineDatabase.get("common").variant).toEqual(0)
        expect(RarityShineDatabase.get("uncommon").variant).toEqual(0)
        expect(RarityShineDatabase.get("rare").variant).toEqual(13)
        expect(RarityShineDatabase.get("legendary").variant).toEqual(1)
        expect(RarityShineDatabase.get("mythic").variant).toEqual(9)
        expect(RarityShineDatabase.get("null").variant).toEqual(15)
        expect(RarityShineDatabase.resolve("Null").id).toEqual("null")
    end,
}
