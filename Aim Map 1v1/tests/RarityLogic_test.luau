return {
    ["blockTone maps CS rarities"] = function(expect)
        local RarityLogic = require("@shared/util/RarityLogic")
        expect(RarityLogic.blockTone("common")).toEqual("blue")
        expect(RarityLogic.blockTone("uncommon")).toEqual("green")
        expect(RarityLogic.blockTone("rare")).toEqual("purple")
        expect(RarityLogic.blockTone("epic")).toEqual("orange")
        expect(RarityLogic.blockTone("legendary")).toEqual("orange")
        expect(RarityLogic.blockTone("mythic")).toEqual("red")
        expect(RarityLogic.blockTone("unknown")).toEqual("blue")
    end,
    ["isValid"] = function(expect)
        local RarityLogic = require("@shared/util/RarityLogic")
        expect(RarityLogic.isValid("rare")).toEqual(true)
        expect(RarityLogic.isValid("nope")).toEqual(false)
    end,
}
