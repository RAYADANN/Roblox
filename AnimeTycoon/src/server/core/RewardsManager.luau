--!strict
-- Timed Rewards: session track (Leaving Resets Progress) + persistent coin/case grants.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local HeroCatalog = require(ReplicatedStorage.shared.data.HeroCatalog)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)
local RewardTrackDatabase = require(ReplicatedStorage.shared.data.RewardTrackDatabase)
local RewardTrackLogic = require(ReplicatedStorage.shared.util.RewardTrackLogic)

type PlayerData = PlayerDataModule.PlayerData

export type ClaimResult = {
    success: boolean,
    error: string?,
    coins: number?,
    coinsGranted: number?,
}

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
}

type Session = {
    startedAt: number,
    claimed: { string },
}

local RewardsManager = {}
RewardsManager.__index = RewardsManager

local function nowSec(): number
    return math.floor(workspace:GetServerTimeNow())
end

function RewardsManager.new(deps: Deps)
    local self = setmetatable({
        _deps = deps,
        _sessions = {} :: { [Player]: Session },
    }, RewardsManager)

    Players.PlayerRemoving:Connect(function(player)
        (self :: any)._sessions[player] = nil
    end)

    return self
end

function RewardsManager:ensureSession(player: Player): Session
    local selfAny = self :: any
    local existing = selfAny._sessions[player]
    if existing then
        return existing
    end
    local session: Session = {
        startedAt = nowSec(),
        claimed = {},
    }
    selfAny._sessions[player] = session
    return session
end

function RewardsManager:getStartedAt(player: Player): number
    return self:ensureSession(player).startedAt
end

function RewardsManager:getClaimed(player: Player): { string }
    return table.clone(self:ensureSession(player).claimed)
end

function RewardsManager:claim(player: Player, rewardId: string): ClaimResult
    if typeof(rewardId) ~= "string" or rewardId == "" then
        return { success = false, error = "invalid_id" }
    end

    local slot = RewardTrackLogic.getSlot(rewardId)
    if not slot then
        return { success = false, error = "unknown_reward" }
    end

    local session = self:ensureSession(player)
    local okClaim, reason =
        RewardTrackLogic.canClaim(rewardId, session.startedAt, session.claimed, nowSec())
    if not okClaim then
        return { success = false, error = reason or "cannot_claim" }
    end

    local deps = (self :: any)._deps
    local pm = deps.profileManager
    if not pm:get(player) then
        return { success = false, error = "no_profile" }
    end

    local coinsGranted = 0
    local failReason: string? = nil

    if slot.rewardType == "money" then
        coinsGranted = math.max(0, math.floor(slot.coins or 0))
        local ok = pm:mutate(player, function(d: PlayerData)
            d.coins += coinsGranted
        end)
        if not ok then
            return { success = false, error = "no_profile" }
        end
    elseif slot.rewardType == "case" then
        local mutation = slot.mutation or "golden"
        local muts = MutationLogic.normalizeStack({ mutation })
        local rarity = if mutation == "galaxy"
            then "mythic"
            elseif mutation == "diamond" then "legendary"
            else "rare"
        local pool = HeroCatalog.pool(rarity)
        local heroId = if #pool > 0 then pool[1] else HeroCatalog.fallbackHeroId()
        local boxModelName = RewardTrackDatabase.caseBoxModelName(mutation)
        local income = ContainerLogic.incomePerMini(rarity, muts)

        local ok = pm:mutate(player, function(d: PlayerData)
            if not d.inventory then
                d.inventory = {}
            end
            if #d.inventory >= Constants.INVENTORY_MAX then
                failReason = "inventory_full"
                return
            end
            local instance = {
                uid = HttpService:GenerateGUID(false),
                templateId = "reward_" .. rewardId,
                boxModelName = boxModelName,
                rarity = rarity :: any,
                heroId = heroId,
                displayName = HeroCatalog.displayName(heroId),
                baseIncome = income,
                mutations = muts,
                placedAt = nil,
                slotIndex = nil,
                unpackProgress = 0,
                unpacked = false,
                incomeRate = income,
            }
            table.insert(d.inventory, instance)
            if d.handUid == nil or d.handUid == "" then
                d.handUid = instance.uid
            end
        end)
        if not ok then
            return { success = false, error = "no_profile" }
        end
        if failReason then
            return { success = false, error = failReason }
        end
    else
        return { success = false, error = "unknown_type" }
    end

    table.insert(session.claimed, rewardId)
    local updated = pm:get(player)
    deps.syncHud(player)
    deps.notify(player, "reward_claimed", rewardId)
    Logger.info("Rewards", `claimed {rewardId} by {player.Name} (+{coinsGranted})`)

    return {
        success = true,
        error = nil,
        coins = if updated then updated.coins else nil,
        coinsGranted = coinsGranted,
    }
end

--- Robux Skip All: rewind track start so every slot is unlocked (still claim manually).
function RewardsManager:skipAll(player: Player): boolean
    local session = self:ensureSession(player)
    local maxMin = RewardTrackDatabase.maxOffsetMin()
    session.startedAt = nowSec() - RewardTrackLogic.offsetSec(maxMin)
    local deps = (self :: any)._deps
    deps.syncHud(player)
    deps.notify(player, "rewards_skip_all", "")
    Logger.info("Rewards", `Skip All for {player.Name}`)
    return true
end

return RewardsManager
