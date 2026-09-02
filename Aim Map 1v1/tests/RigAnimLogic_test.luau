local RigAnimLogic = require("@shared/util/RigAnimLogic")

return {
    ["shouldWalk: at threshold"] = function(expect)
        expect(RigAnimLogic.shouldWalk(2.5, 2.5)).toEqual(true)
        expect(RigAnimLogic.shouldWalk(2.4, 2.5)).toEqual(false)
    end,
    ["shouldWalk: rejects nan"] = function(expect)
        expect(RigAnimLogic.shouldWalk(0 / 0, 2.5)).toEqual(false)
    end,
    ["isNear: inclusive range"] = function(expect)
        expect(RigAnimLogic.isNear(0, 16)).toEqual(true)
        expect(RigAnimLogic.isNear(16, 16)).toEqual(true)
        expect(RigAnimLogic.isNear(16.1, 16)).toEqual(false)
    end,
}
