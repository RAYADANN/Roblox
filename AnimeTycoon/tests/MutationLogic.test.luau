return {
    ["pickRarity is deterministic for edges"] = function(expect)
        local MutationLogic = require("../src/shared/util/MutationLogic")
        expect(MutationLogic.pickRarity(0)).toEqual("common")
        local late = MutationLogic.pickRarity(0.999)
        expect(late == "legendary" or late == "epic" or late == "rare").toBeTruthy()
    end,
    ["formatLabel joins names"] = function(expect)
        local MutationLogic = require("../src/shared/util/MutationLogic")
        expect(MutationLogic.formatLabel({ "golden", "neon" })).toEqual("Golden-Neon")
        expect(MutationLogic.formatLabel({})).toEqual("")
    end,
}
