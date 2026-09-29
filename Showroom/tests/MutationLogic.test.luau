--!strict
local MutationLogic = require("../src/shared/util/MutationLogic")
local NpcEmotionDatabase = require("../src/shared/data/NpcEmotionDatabase")

return {
    ["shouldMutate respects chance"] = function(expect)
        expect(MutationLogic.shouldMutate("common", 0)).toBeTruthy()
        expect(MutationLogic.shouldMutate("common", 0.99)).toBeFalsy()
    end,
    ["rollDuringGrowth: zero dt never"] = function(expect)
        expect(MutationLogic.rollDuringGrowth("rare", 0, false, 0)).toBeFalsy()
    end,
    ["rollDuringGrowth: long dt can trigger"] = function(expect)
        expect(MutationLogic.rollDuringGrowth("legendary", 90, false, 0)).toBeTruthy()
    end,
    ["formatLabel joins with dashes"] = function(expect)
        expect(MutationLogic.formatLabel({ "spark", "neon" })).toEqual("Spark-Neon")
        expect(MutationLogic.formatLabel({})).toEqual("")
    end,
    ["rollEggMutations: miss returns empty"] = function(expect)
        local ids = MutationLogic.rollEggMutations("common", 0.99, 0)
        expect(#ids).toEqual(0)
    end,
    ["rollEggMutations: hit returns one growth id"] = function(expect)
        local ids = MutationLogic.rollEggMutations("legendary", 0, 0)
        expect(#ids).toEqual(1)
        expect(ids[1] ~= nil).toBeTruthy()
    end,
    ["pickGrowthId skips owned"] = function(expect)
        local id = MutationLogic.pickGrowthId({ "spark" }, 0)
        expect(id ~= nil).toBeTruthy()
        expect(id ~= "spark").toBeTruthy()
    end,
    ["pickLonelyId returns lonely"] = function(expect)
        local id = MutationLogic.pickLonelyId({}, 0)
        expect(id == "forsaken" or id == "hollow" or id == "ghosted").toBeTruthy()
    end,
    ["shouldAvoidNpcs respects chance"] = function(expect)
        expect(MutationLogic.shouldAvoidNpcs("common", 0)).toBeTruthy()
        expect(MutationLogic.shouldAvoidNpcs("common", 0.99)).toBeFalsy()
    end,
    ["pickRarity: low roll common-ish"] = function(expect)
        local r = MutationLogic.pickRarity(0)
        expect(r).toEqual("common")
    end,
    ["pickTemplate returns id"] = function(expect)
        local id = MutationLogic.pickTemplate(0)
        expect(type(id) == "string").toBeTruthy()
        expect(#id > 0).toBeTruthy()
    end,
    ["npc emotion by rarity"] = function(expect)
        local e = NpcEmotionDatabase.pick("legendary", 0)
        expect(type(e) == "string").toBeTruthy()
        expect(#e > 0).toBeTruthy()
        local c = NpcEmotionDatabase.pickCelebrate(0)
        expect(#c > 0).toBeTruthy()
        local w = NpcEmotionDatabase.pickWalk(0)
        expect(#w > 0).toBeTruthy()
    end,
}
