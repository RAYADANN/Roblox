--!strict
local IndexLogic = require("../src/shared/util/IndexLogic")

return {
    ["cards: one entry per hero"] = function(expect)
        expect(#IndexLogic.cards(0)).toEqual(20)
    end,
    ["cards: name is uppercase model name"] = function(expect)
        local first = IndexLogic.cards(0)[1]
        expect(first.name).toEqual("SUSHI MAN")
        expect(first.modelName).toEqual("Sushi Man")
    end,
    ["cards: locked shows ??? for drop points"] = function(expect)
        local first = IndexLogic.cards(0)[1]
        expect(first.unlocked).toEqual(false)
        expect(first.countLabel).toEqual("???")
        expect(first.count).toEqual(10)
    end,
    ["cards: unlocked shows drop points"] = function(expect)
        local first = IndexLogic.cards(1)[1]
        local second = IndexLogic.cards(1)[2]
        expect(first.unlocked).toEqual(true)
        expect(first.countLabel).toEqual("10")
        expect(second.unlocked).toEqual(false)
        expect(second.countLabel).toEqual("???")
        expect(second.count).toEqual(20)
    end,
    ["columnCount: 4 for the Index grid"] = function(expect)
        expect(IndexLogic.columnCount()).toEqual(4)
    end,
    ["rememberTiers: persists highest owned tier"] = function(expect)
        expect(IndexLogic.rememberTiers(0, { 2, 2, 1 })).toEqual(2)
    end,
}
