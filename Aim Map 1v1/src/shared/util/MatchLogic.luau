--!strict
-- Pure match rules: first-to-N, kill scoring, rematch readiness.
-- Dual require: Roblox Instance path / Lune @shared (CI).
--# selene: allow(incorrect_standard_library_use)

local Constants = if script
    then require(script.Parent.Parent.data.Constants)
    else require("@shared/data/Constants")

local BotCombatLogic = if script
    then require(script.Parent.BotCombatLogic)
    else require("@shared/util/BotCombatLogic")

export type MatchPhase = "Waiting" | "Live" | "Ended"

export type MatchState = {
    matchId: string,
    phase: MatchPhase,
    firstTo: number,
    userIdA: number,
    userIdB: number,
    scoreA: number,
    scoreB: number,
    rematchA: boolean,
    rematchB: boolean,
    winnerUserId: number?,
}

local MatchLogic = {}

function MatchLogic.create(
    matchId: string,
    userIdA: number,
    userIdB: number,
    firstTo: number?
): MatchState
    local target = if firstTo and firstTo > 0 then firstTo else Constants.MATCH_FIRST_TO
    return {
        matchId = matchId,
        phase = "Live",
        firstTo = target,
        userIdA = userIdA,
        userIdB = userIdB,
        scoreA = 0,
        scoreB = 0,
        rematchA = false,
        rematchB = false,
        winnerUserId = nil,
    }
end

function MatchLogic.sideOf(state: MatchState, userId: number): ("A" | "B")?
    if userId == state.userIdA then
        return "A"
    elseif userId == state.userIdB then
        return "B"
    end
    return nil
end

function MatchLogic.opponentOf(state: MatchState, userId: number): number?
    local side = MatchLogic.sideOf(state, userId)
    if side == "A" then
        return state.userIdB
    elseif side == "B" then
        return state.userIdA
    end
    return nil
end

function MatchLogic.scoreOf(state: MatchState, userId: number): number
    local side = MatchLogic.sideOf(state, userId)
    if side == "A" then
        return state.scoreA
    elseif side == "B" then
        return state.scoreB
    end
    return 0
end

--- Apply a kill. Returns whether the match just ended.
function MatchLogic.applyKill(state: MatchState, killerUserId: number): (MatchState, boolean)
    if state.phase ~= "Live" then
        return state, false
    end
    local side = MatchLogic.sideOf(state, killerUserId)
    if not side then
        return state, false
    end

    local nextState: MatchState = {
        matchId = state.matchId,
        phase = state.phase,
        firstTo = state.firstTo,
        userIdA = state.userIdA,
        userIdB = state.userIdB,
        scoreA = state.scoreA,
        scoreB = state.scoreB,
        rematchA = state.rematchA,
        rematchB = state.rematchB,
        winnerUserId = state.winnerUserId,
    }

    if side == "A" then
        nextState.scoreA += 1
    else
        nextState.scoreB += 1
    end

    local killerScore = if side == "A" then nextState.scoreA else nextState.scoreB
    if killerScore >= nextState.firstTo then
        nextState.phase = "Ended"
        nextState.winnerUserId = killerUserId
        return nextState, true
    end

    return nextState, false
end

function MatchLogic.setRematchReady(state: MatchState, userId: number, ready: boolean): MatchState
    if state.phase ~= "Ended" then
        return state
    end
    local side = MatchLogic.sideOf(state, userId)
    if not side then
        return state
    end
    local nextState: MatchState = {
        matchId = state.matchId,
        phase = state.phase,
        firstTo = state.firstTo,
        userIdA = state.userIdA,
        userIdB = state.userIdB,
        scoreA = state.scoreA,
        scoreB = state.scoreB,
        rematchA = state.rematchA,
        rematchB = state.rematchB,
        winnerUserId = state.winnerUserId,
    }
    if side == "A" then
        nextState.rematchA = ready
    else
        nextState.rematchB = ready
    end
    return nextState
end

function MatchLogic.bothWantRematch(state: MatchState): boolean
    return state.phase == "Ended" and state.rematchA and state.rematchB
end

function MatchLogic.resetForRematch(state: MatchState, newMatchId: string): MatchState
    return MatchLogic.create(newMatchId, state.userIdA, state.userIdB, state.firstTo)
end

function MatchLogic.isBotUserId(userId: number): boolean
    return BotCombatLogic.isBotUserId(userId)
end

function MatchLogic.isBotMatch(state: MatchState): boolean
    return BotCombatLogic.isBotUserId(state.userIdA) or BotCombatLogic.isBotUserId(state.userIdB)
end

return MatchLogic
