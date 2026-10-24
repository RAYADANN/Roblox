--!strict
local TutorialLogic = require("../src/shared/util/TutorialLogic")

return {
    ["resolveStep: starts on the first flag"] = function(expect)
        expect(TutorialLogic.resolveStep({})).toEqual(1)
    end,
    ["resolveStep: first flag advances to the second step"] = function(expect)
        expect(TutorialLogic.resolveStep({ didAct = true })).toEqual(2)
    end,
    ["resolveStep: both flags finish"] = function(expect)
        expect(TutorialLogic.resolveStep({ didAct = true, didReward = true })).toEqual(0)
    end,
    ["advance: does not move backwards"] = function(expect)
        expect(TutorialLogic.advance(2, {})).toEqual(2)
    end,
    ["advanceOne: one satisfied step"] = function(expect)
        expect(TutorialLogic.advanceOne(1, { didAct = true })).toEqual(2)
        expect(TutorialLogic.advanceOne(2, { didAct = true, didReward = true })).toEqual(0)
    end,
    ["getStep: placeholder copy is two steps"] = function(expect)
        expect(TutorialLogic.stepCount()).toEqual(2)
        local first = TutorialLogic.getStep(1)
        expect(if first then first.flag else "").toEqual("didAct")
    end,
}
