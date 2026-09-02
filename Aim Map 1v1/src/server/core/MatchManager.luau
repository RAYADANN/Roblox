--!strict
-- 1v1 duel lifecycle: queue → live → score → rematch (+ optional bot opponent).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArenaBootstrap = require(script.Parent.ArenaBootstrap)
local BotAgentManager = require(script.Parent.BotAgentManager)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local GameAnalytics = require(script.Parent.GameAnalytics)
local KillFlexLogic = require(ReplicatedStorage.shared.util.KillFlexLogic)
local MatchLogic = require(ReplicatedStorage.shared.util.MatchLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local ProfileManager = require(script.Parent.ProfileManager)
local SkinPublisher = require(script.Parent.SkinPublisher)
local UniformCharacter = require(script.Parent.UniformCharacter)

type MatchState = MatchLogic.MatchState
type FlexState = KillFlexLogic.FlexState
type MatchSyncPayload = NetTypes.MatchSyncPayload
type HudSyncPayload = NetTypes.HudSyncPayload

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player, payload: HudSyncPayload?) -> (),
    syncMatch: (player: Player, payload: MatchSyncPayload) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
    offerSkinEquip: (player: Player, skinId: string, owned: boolean) -> (),
    botAgent: BotAgentManager.BotAgentManager,
}

export type MatchManager = {
    enqueue: (self: MatchManager, player: Player) -> (),
    leave: (self: MatchManager, player: Player) -> (),
    startBotMatch: (self: MatchManager, player: Player) -> NetTypes.StartBotMatchResult,
    requestRematch: (self: MatchManager, player: Player) -> NetTypes.RematchResult,
    getMatchFor: (self: MatchManager, player: Player) -> MatchState?,
    getOpponent: (self: MatchManager, player: Player) -> Player?,
    isAliveInMatch: (self: MatchManager, player: Player) -> boolean,
    isBotCharacter: (self: MatchManager, model: Model) -> boolean,
    isBotAliveInMatch: (self: MatchManager, matchId: string) -> boolean,
    getPlayerForBotMatch: (self: MatchManager, matchId: string) -> Player?,
    isMatchLive: (self: MatchManager, matchId: string) -> boolean,
    onKill: (self: MatchManager, killer: Player, victim: Player) -> (),
    onPlayerKillBot: (self: MatchManager, killer: Player, botModel: Model) -> (),
    onBotKillPlayer: (self: MatchManager, botModel: Model, victim: Player) -> (),
    onEquippedSkinChanged: (self: MatchManager, player: Player, skinId: string) -> (),
    getFlexVisible: (self: MatchManager, player: Player) -> string,
    start: (self: MatchManager) -> (),
}

local MatchManager = {}
MatchManager.__index = MatchManager

local function emptyFlex(baseSkinId: string): FlexState
    return { baseSkinId = baseSkinId, flexSkinId = nil }
end

function MatchManager.new(deps: Deps): MatchManager
    local spawns = ArenaBootstrap.ensure()
    return setmetatable({
        _deps = deps,
        _queue = {} :: { Player },
        _byPlayer = {} :: { [Player]: string },
        _matches = {} :: { [string]: MatchState },
        _flex = {} :: { [Player]: FlexState },
        _alive = {} :: { [Player]: boolean },
        _botAlive = {} :: { [string]: boolean },
        _matchSeq = 0,
        _spawns = spawns,
    }, MatchManager) :: any
end

function MatchManager:start()
    Players.PlayerRemoving:Connect(function(player)
        self:leave(player)
    end)
end

function MatchManager:_baseSkin(player: Player): string
    local data = self._deps.profileManager:get(player)
    if data and data.equippedSkinId ~= "" then
        return data.equippedSkinId
    end
    return Constants.DEFAULT_SKIN_ID
end

function MatchManager:_publishSkin(player: Player)
    local flex = self._flex[player] or emptyFlex(self:_baseSkin(player))
    SkinPublisher.publish(player, flex.baseSkinId, flex.flexSkinId)
end

function MatchManager:onEquippedSkinChanged(player: Player, skinId: string)
    local flex = self._flex[player]
    if flex then
        self._flex[player] = {
            baseSkinId = skinId,
            flexSkinId = flex.flexSkinId,
        }
    end
    self:_publishSkin(player)

    local state = self:getMatchFor(player)
    if state then
        self:_syncBoth(state)
    end
end

function MatchManager:getFlexVisible(player: Player): string
    local flex = self._flex[player]
    if not flex then
        return self:_baseSkin(player)
    end
    return KillFlexLogic.visibleSkin(flex)
end

function MatchManager:getMatchFor(player: Player): MatchState?
    local id = self._byPlayer[player]
    if not id then
        return nil
    end
    return self._matches[id]
end

function MatchManager:isMatchLive(matchId: string): boolean
    local state = self._matches[matchId]
    return state ~= nil and state.phase == "Live"
end

function MatchManager:getPlayerForBotMatch(matchId: string): Player?
    local state = self._matches[matchId]
    if not state or not MatchLogic.isBotMatch(state) then
        return nil
    end
    local humanId = if MatchLogic.isBotUserId(state.userIdA) then state.userIdB else state.userIdA
    return Players:GetPlayerByUserId(humanId)
end

function MatchManager:isBotCharacter(model: Model): boolean
    return self._deps.botAgent:isBot(model)
end

function MatchManager:isBotAliveInMatch(matchId: string): boolean
    local state = self._matches[matchId]
    if not state or state.phase ~= "Live" then
        return false
    end
    return self._botAlive[matchId] == true
end

function MatchManager:getOpponent(player: Player): Player?
    local state = self:getMatchFor(player)
    if not state then
        return nil
    end
    local oppId = MatchLogic.opponentOf(state, player.UserId)
    if not oppId or MatchLogic.isBotUserId(oppId) then
        return nil
    end
    return Players:GetPlayerByUserId(oppId)
end

function MatchManager:isAliveInMatch(player: Player): boolean
    local state = self:getMatchFor(player)
    if not state or state.phase ~= "Live" then
        return false
    end
    return self._alive[player] == true
end

function MatchManager:_payloadFor(player: Player, state: MatchState): MatchSyncPayload
    local opp = self:getOpponent(player)
    local oppUserId = MatchLogic.opponentOf(state, player.UserId)
    local isBot = oppUserId ~= nil and MatchLogic.isBotUserId(oppUserId)
    local oppName = if isBot
        then Constants.BOT_DISPLAY_NAME
        elseif opp then opp.DisplayName
        else "Opponent"
    local youScore = MatchLogic.scoreOf(state, player.UserId)
    local oppScore = if oppUserId then MatchLogic.scoreOf(state, oppUserId) else 0
    local side = MatchLogic.sideOf(state, player.UserId)
    local youReady = if side == "A"
        then state.rematchA
        elseif side == "B" then state.rematchB
        else false
    local oppReady = if side == "A"
        then state.rematchB
        elseif side == "B" then state.rematchA
        else false

    return {
        matchId = state.matchId,
        phase = state.phase,
        firstTo = state.firstTo,
        youScore = youScore,
        oppScore = oppScore,
        oppName = oppName,
        canRematch = state.phase == "Ended",
        youReadyRematch = youReady,
        oppReadyRematch = oppReady,
        visibleSkinId = self:getFlexVisible(player),
        oppVisibleSkinId = if opp then self:getFlexVisible(opp) else Constants.DEFAULT_SKIN_ID,
    }
end

function MatchManager:_syncBoth(state: MatchState)
    local a = Players:GetPlayerByUserId(state.userIdA)
    local b = Players:GetPlayerByUserId(state.userIdB)
    if a then
        self._deps.syncMatch(a, self:_payloadFor(a, state))
    end
    if b then
        self._deps.syncMatch(b, self:_payloadFor(b, state))
    end
end

function MatchManager:_teleport(player: Player, cf: CFrame)
    local character = player.Character
    if not character then
        return
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        root.CFrame = cf
    end
end

function MatchManager:_resetCombatant(player: Player, spawnCf: CFrame)
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    local needsFresh = character == nil
        or character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true
        or (humanoid ~= nil and humanoid.Health <= 0)
    if needsFresh then
        -- Custom dummy + LoadCharacter after ragdoll often leaves Character nil.
        character = UniformCharacter.respawnAt(player, spawnCf)
    else
        if humanoid then
            humanoid.MaxHealth = Constants.MATCH_PLAYER_HP
            humanoid.Health = Constants.MATCH_PLAYER_HP
            humanoid.PlatformStand = false
        end
        self:_teleport(player, spawnCf)
        character = player.Character
    end
    if not character then
        return
    end
    self._alive[player] = true
end

function MatchManager:_roundReset(state: MatchState)
    local a = Players:GetPlayerByUserId(state.userIdA)
    local b = Players:GetPlayerByUserId(state.userIdB)
    if a then
        self:_resetCombatant(a, self._spawns.spawnA)
    end
    if b then
        self:_resetCombatant(b, self._spawns.spawnB)
    end
    if MatchLogic.isBotMatch(state) then
        local live = state.phase == "Live"
        if live then
            self._deps.botAgent:resetForRound(state.matchId, self._spawns.spawnB)
        end
        self._botAlive[state.matchId] = live
        self._deps.botAgent:setActive(state.matchId, live)
    end
end

function MatchManager:_clearMatchSlot(state: MatchState)
    local a = Players:GetPlayerByUserId(state.userIdA)
    local b = Players:GetPlayerByUserId(state.userIdB)
    self._matches[state.matchId] = nil
    self._botAlive[state.matchId] = nil
    if a then
        self._byPlayer[a] = nil
    end
    if b then
        self._byPlayer[b] = nil
    end
    if MatchLogic.isBotMatch(state) then
        self._deps.botAgent:destroyForMatch(state.matchId)
    end
end

function MatchManager:_startMatch(playerA: Player, playerB: Player)
    self._matchSeq += 1
    local matchId = `m{self._matchSeq}`
    local state =
        MatchLogic.create(matchId, playerA.UserId, playerB.UserId, Constants.MATCH_FIRST_TO)
    self._matches[matchId] = state
    self._byPlayer[playerA] = matchId
    self._byPlayer[playerB] = matchId

    self._flex[playerA] = emptyFlex(self:_baseSkin(playerA))
    self._flex[playerB] = emptyFlex(self:_baseSkin(playerB))
    self:_publishSkin(playerA)
    self:_publishSkin(playerB)

    self:_roundReset(state)
    self:_syncBoth(state)

    GameAnalytics.log(playerA, "duel_start", 1)
    GameAnalytics.log(playerB, "duel_start", 1)
    self._deps.notify(playerA, "match_start", playerB.DisplayName)
    self._deps.notify(playerB, "match_start", playerA.DisplayName)
end

function MatchManager:_startBotMatchInternal(player: Player)
    -- Drop queue seat if any.
    local qi = table.find(self._queue, player)
    if qi then
        table.remove(self._queue, qi)
    end

    self._matchSeq += 1
    local matchId = `m{self._matchSeq}`
    local state =
        MatchLogic.create(matchId, player.UserId, Constants.BOT_USER_ID, Constants.MATCH_FIRST_TO)
    self._matches[matchId] = state
    self._byPlayer[player] = matchId
    self._flex[player] = emptyFlex(self:_baseSkin(player))
    self:_publishSkin(player)

    self._deps.botAgent:spawnForMatch(matchId, self._spawns.spawnB)
    self._botAlive[matchId] = true
    self:_roundReset(state)
    self:_syncBoth(state)

    GameAnalytics.log(player, "duel_start", 1)
    self._deps.notify(player, "match_start", Constants.BOT_DISPLAY_NAME)
end

function MatchManager:startBotMatch(player: Player): NetTypes.StartBotMatchResult
    if self._byPlayer[player] then
        return { success = false, error = "in_match" }
    end
    if not player.Character then
        return { success = false, error = "no_character" }
    end
    self:_startBotMatchInternal(player)
    return { success = true }
end

function MatchManager:_tryPair()
    while #self._queue >= 2 do
        local a = table.remove(self._queue, 1)
        local b = table.remove(self._queue, 1)
        if a and a.Parent and b and b.Parent and a ~= b then
            self:_startMatch(a, b)
        elseif a and a.Parent then
            table.insert(self._queue, 1, a)
            break
        elseif b and b.Parent then
            table.insert(self._queue, 1, b)
            break
        end
    end
end

function MatchManager:enqueue(player: Player)
    if self._byPlayer[player] then
        return
    end
    if table.find(self._queue, player) then
        return
    end
    table.insert(self._queue, player)
    self._flex[player] = emptyFlex(self:_baseSkin(player))
    self:_publishSkin(player)
    local function putAtPractice()
        if self._byPlayer[player] then
            return
        end
        if player.Character then
            self:_teleport(player, self._spawns.spawnA)
        end
    end
    if player.Character then
        putAtPractice()
    else
        player.CharacterAdded:Once(putAtPractice)
    end
    self:_tryPair()
end

function MatchManager:leave(player: Player)
    local qi = table.find(self._queue, player)
    if qi then
        table.remove(self._queue, qi)
    end

    local matchId = self._byPlayer[player]
    self._byPlayer[player] = nil
    self._alive[player] = nil
    self._flex[player] = nil
    SkinPublisher.clearFlex(player)

    if not matchId then
        return
    end
    local state = self._matches[matchId]
    if not state then
        return
    end

    local oppId = MatchLogic.opponentOf(state, player.UserId)
    local opp = if oppId and not MatchLogic.isBotUserId(oppId)
        then Players:GetPlayerByUserId(oppId)
        else nil

    self:_clearMatchSlot(state)

    if opp then
        self._deps.notify(opp, "opponent_left", player.DisplayName)
        self:enqueue(opp)
    end
end

function MatchManager:_recordResult(state: MatchState)
    local winnerId = state.winnerUserId
    if not winnerId then
        return
    end
    local loserId = MatchLogic.opponentOf(state, winnerId)
    local winner = if MatchLogic.isBotUserId(winnerId)
        then nil
        else Players:GetPlayerByUserId(winnerId)
    local loser = if loserId and not MatchLogic.isBotUserId(loserId)
        then Players:GetPlayerByUserId(loserId)
        else nil
    local pm = self._deps.profileManager

    if winner then
        pm:mutate(winner, function(d)
            d.wins += 1
        end)
        self._deps.syncHud(winner, nil)
        GameAnalytics.log(winner, "duel_end", 1)
    end
    if loser then
        pm:mutate(loser, function(d)
            d.losses += 1
        end)
        self._deps.syncHud(loser, nil)
        GameAnalytics.log(loser, "duel_end", 0)
    end
end

function MatchManager:_afterKill(
    nextState: MatchState,
    killerName: string,
    victimName: string,
    notifyPlayer: Player?,
    notifyVictim: Player?
)
    if notifyPlayer then
        self._deps.notify(notifyPlayer, "kill", victimName)
    end
    if notifyVictim then
        self._deps.notify(notifyVictim, "death", killerName)
    end

    -- Freeze combat for the death window so the bot cannot shoot a corpse / hang the round.
    if MatchLogic.isBotMatch(nextState) then
        self._deps.botAgent:setActive(nextState.matchId, false)
    end

    if nextState.phase == "Ended" then
        self:_recordResult(nextState)
    end
    self:_syncBoth(nextState)

    local matchId = nextState.matchId
    task.delay(Constants.ROUND_RESET_DELAY_SEC, function()
        local current = self._matches[matchId]
        if not current then
            return
        end
        if current.phase == "Live" or current.phase == "Ended" then
            self:_roundReset(current)
            self:_syncBoth(current)
        end
    end)
end

function MatchManager:onKill(killer: Player, victim: Player)
    local state = self:getMatchFor(killer)
    if not state or state.phase ~= "Live" then
        return
    end
    if self._byPlayer[victim] ~= state.matchId then
        return
    end
    if self._alive[victim] ~= true then
        return
    end

    self._alive[victim] = false

    local victimFlex = self._flex[victim] or emptyFlex(self:_baseSkin(victim))
    local victimVisible = KillFlexLogic.visibleSkin(victimFlex)
    local killerFlex = self._flex[killer] or emptyFlex(self:_baseSkin(killer))
    self._flex[killer] = KillFlexLogic.onKill(killerFlex, victimVisible)
    self._flex[victim] = KillFlexLogic.onDeath(victimFlex)
    self:_publishSkin(killer)
    self:_publishSkin(victim)

    local killerData = self._deps.profileManager:get(killer)
    local owned = killerData ~= nil and killerData.ownedSkins[victimVisible] == true
    self._deps.offerSkinEquip(killer, victimVisible, owned)

    local nextState, _ended = MatchLogic.applyKill(state, killer.UserId)
    self._matches[state.matchId] = nextState
    self:_afterKill(nextState, killer.DisplayName, victim.DisplayName, killer, victim)
end

function MatchManager:onPlayerKillBot(killer: Player, botModel: Model)
    local state = self:getMatchFor(killer)
    if not state or state.phase ~= "Live" or not MatchLogic.isBotMatch(state) then
        return
    end
    if not self._deps.botAgent:isBot(botModel) then
        return
    end
    if self._botAlive[state.matchId] ~= true then
        return
    end

    self._botAlive[state.matchId] = false
    self._deps.botAgent:markDead(state.matchId)
    -- Killer stays alive between rounds so fire keeps working.
    self._alive[killer] = true

    local killerFlex = self._flex[killer] or emptyFlex(self:_baseSkin(killer))
    local offerSkinId = Constants.DEFAULT_SKIN_ID
    self._flex[killer] = KillFlexLogic.onKill(killerFlex, offerSkinId)
    self:_publishSkin(killer)

    local killerData = self._deps.profileManager:get(killer)
    local owned = killerData ~= nil and killerData.ownedSkins[offerSkinId] == true
    self._deps.offerSkinEquip(killer, offerSkinId, owned)

    local nextState, _ended = MatchLogic.applyKill(state, killer.UserId)
    self._matches[state.matchId] = nextState
    self:_afterKill(nextState, killer.DisplayName, Constants.BOT_DISPLAY_NAME, killer, nil)
end

function MatchManager:onBotKillPlayer(botModel: Model, victim: Player)
    local state = self:getMatchFor(victim)
    if not state or state.phase ~= "Live" or not MatchLogic.isBotMatch(state) then
        return
    end
    if not self._deps.botAgent:isBot(botModel) then
        return
    end
    if self._alive[victim] ~= true then
        return
    end

    self._alive[victim] = false
    self._deps.botAgent:setActive(state.matchId, false)

    local victimFlex = self._flex[victim] or emptyFlex(self:_baseSkin(victim))
    self._flex[victim] = KillFlexLogic.onDeath(victimFlex)
    self:_publishSkin(victim)

    local nextState, _ended = MatchLogic.applyKill(state, Constants.BOT_USER_ID)
    self._matches[state.matchId] = nextState
    self:_afterKill(nextState, Constants.BOT_DISPLAY_NAME, victim.DisplayName, nil, victim)
end

function MatchManager:_beginRematch(state: MatchState)
    local oldId = state.matchId
    local a = Players:GetPlayerByUserId(state.userIdA)
    local b = Players:GetPlayerByUserId(state.userIdB)
    local wasBot = MatchLogic.isBotMatch(state)

    self._matches[oldId] = nil
    self._botAlive[oldId] = nil
    if a then
        self._byPlayer[a] = nil
    end
    if b then
        self._byPlayer[b] = nil
    end

    if wasBot then
        self._deps.botAgent:destroyForMatch(oldId)
        local human = a or b
        if human and human.Parent then
            self:_startBotMatchInternal(human)
        end
        return
    end

    if a and b and a.Parent and b.Parent then
        self:_startMatch(a, b)
    end
end

function MatchManager:requestRematch(player: Player): NetTypes.RematchResult
    local state = self:getMatchFor(player)
    if not state then
        return { success = false, error = "no_match" }
    end
    if state.phase ~= "Ended" then
        return { success = false, error = "not_ended" }
    end

    local nextState = MatchLogic.setRematchReady(state, player.UserId, true)
    self._matches[state.matchId] = nextState
    self:_syncBoth(nextState)
    GameAnalytics.log(player, "rematch", 1)

    if MatchLogic.isBotMatch(nextState) then
        local matchId = nextState.matchId
        task.delay(Constants.BOT_REMATCH_DELAY_SEC, function()
            local current = self._matches[matchId]
            if not current or current.phase ~= "Ended" then
                return
            end
            local withBot = MatchLogic.setRematchReady(current, Constants.BOT_USER_ID, true)
            self._matches[matchId] = withBot
            self:_syncBoth(withBot)
            if MatchLogic.bothWantRematch(withBot) then
                self:_beginRematch(withBot)
            end
        end)
        return { success = true }
    end

    if MatchLogic.bothWantRematch(nextState) then
        self:_beginRematch(nextState)
    end

    return { success = true }
end

return MatchManager
