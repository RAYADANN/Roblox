local MatchLogic = require("@shared/util/MatchLogic")

return {
    ["create starts Live first-to default"] = function(expect)
        local state = MatchLogic.create("m1", 1, 2)
        expect(state.phase).toEqual("Live")
        expect(state.firstTo).toEqual(5)
        expect(state.scoreA).toEqual(0)
        expect(state.scoreB).toEqual(0)
    end,

    ["applyKill increments and ends at firstTo"] = function(expect)
        local state = MatchLogic.create("m1", 10, 20, 2)
        local s1, ended1 = MatchLogic.applyKill(state, 10)
        expect(ended1).toEqual(false)
        expect(s1.scoreA).toEqual(1)
        expect(s1.phase).toEqual("Live")

        local s2, ended2 = MatchLogic.applyKill(s1, 10)
        expect(ended2).toEqual(true)
        expect(s2.scoreA).toEqual(2)
        expect(s2.phase).toEqual("Ended")
        expect(s2.winnerUserId).toEqual(10)
    end,

    ["rematch requires both after Ended"] = function(expect)
        local state = MatchLogic.create("m1", 1, 2, 1)
        state, _ = MatchLogic.applyKill(state, 1)
        expect(MatchLogic.bothWantRematch(state)).toEqual(false)

        state = MatchLogic.setRematchReady(state, 1, true)
        expect(MatchLogic.bothWantRematch(state)).toEqual(false)
        state = MatchLogic.setRematchReady(state, 2, true)
        expect(MatchLogic.bothWantRematch(state)).toEqual(true)

        local rematch = MatchLogic.resetForRematch(state, "m2")
        expect(rematch.matchId).toEqual("m2")
        expect(rematch.phase).toEqual("Live")
        expect(rematch.scoreA).toEqual(0)
        expect(rematch.rematchA).toEqual(false)
    end,

    ["unknown killer is ignored"] = function(expect)
        local state = MatchLogic.create("m1", 1, 2, 3)
        local nextState, ended = MatchLogic.applyKill(state, 99)
        expect(ended).toEqual(false)
        expect(nextState.scoreA).toEqual(0)
        expect(nextState.scoreB).toEqual(0)
    end,

    ["bot match helpers"] = function(expect)
        local Constants = require("@shared/data/Constants")
        local state = MatchLogic.create("m1", 10, Constants.BOT_USER_ID, 3)
        expect(MatchLogic.isBotMatch(state)).toEqual(true)
        expect(MatchLogic.isBotUserId(Constants.BOT_USER_ID)).toEqual(true)

        local s1, ended = MatchLogic.applyKill(state, Constants.BOT_USER_ID)
        expect(ended).toEqual(false)
        expect(s1.scoreB).toEqual(1)

        local endedState = MatchLogic.create("m3", 10, Constants.BOT_USER_ID, 1)
        endedState, _ = MatchLogic.applyKill(endedState, 10)
        endedState = MatchLogic.setRematchReady(endedState, 10, true)
        endedState = MatchLogic.setRematchReady(endedState, Constants.BOT_USER_ID, true)
        expect(MatchLogic.bothWantRematch(endedState)).toEqual(true)
    end,
}
