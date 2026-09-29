--!strict
local HeroLogic = require("../src/shared/util/HeroLogic")

return {
    ["count: 20 characters from Studio catalog"] = function(expect)
        expect(HeroLogic.count()).toEqual(20)
    end,
    ["modelNameForTier: first and last match folder order"] = function(expect)
        expect(HeroLogic.modelNameForTier(1)).toEqual("Sushi Man")
        expect(HeroLogic.modelNameForTier(20)).toEqual("NONAME")
    end,
    ["modelNameForTier: above catalog reuses last hero"] = function(expect)
        expect(HeroLogic.modelNameForTier(21)).toEqual("NONAME")
        expect(HeroLogic.modelNameForTier(99)).toEqual("NONAME")
    end,
    ["displayName: uppercase from model name"] = function(expect)
        expect(HeroLogic.displayName("samurai girl")).toEqual("SAMURAI GIRL")
        expect(HeroLogic.displayName("Agebt Snake")).toEqual("AGEBT SNAKE")
    end,
    ["slugId: stable card id"] = function(expect)
        expect(HeroLogic.slugId("Sushi Man")).toEqual("sushi_man")
        expect(HeroLogic.slugId("NONAME")).toEqual("noname")
    end,
    ["rememberTiers: keeps the highest owned merge tier"] = function(expect)
        expect(HeroLogic.rememberTiers(1, { 3, 1, 2 })).toEqual(3)
        expect(HeroLogic.rememberTiers(5, { 1, 1 })).toEqual(5)
    end,
}
