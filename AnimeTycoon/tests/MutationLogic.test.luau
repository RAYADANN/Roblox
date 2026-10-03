return {
    ["pickRarity is deterministic for edges"] = function(expect)
        local MutationLogic = require("../src/shared/util/MutationLogic")
        expect(MutationLogic.pickRarity(0)).toEqual("common")
        local late = MutationLogic.pickRarity(0.999)
        expect(late == "legendary" or late == "mythic" or late == "rare").toBeTruthy()
    end,
    ["formatLabel is single mutation only"] = function(expect)
        local MutationLogic = require("../src/shared/util/MutationLogic")
        expect(MutationLogic.formatLabel({ "golden" })).toEqual("Golden")
        expect(MutationLogic.formatLabel({ "golden", "secret" })).toEqual("Golden")
        expect(MutationLogic.formatLabel({})).toEqual("")
    end,
    ["normalizeStack keeps at most one"] = function(expect)
        local MutationLogic = require("../src/shared/util/MutationLogic")
        local one = MutationLogic.normalizeStack({ "golden", "secret" })
        expect(#one).toEqual(1)
        expect(one[1]).toEqual("golden")
        expect(#MutationLogic.normalizeStack({})).toEqual(0)
        expect(#MutationLogic.normalizeStack(nil)).toEqual(0)
    end,
    ["rollOfferMutations returns 0 or 1 id"] = function(expect)
        local MutationLogic = require("../src/shared/util/MutationLogic")
        local none = MutationLogic.rollOfferMutations("common", 0.99, 0.5)
        expect(#none).toEqual(0)
        local some = MutationLogic.rollOfferMutations("mythic", 0, 0.1)
        expect(#some <= 1).toBeTruthy()
    end,
}
