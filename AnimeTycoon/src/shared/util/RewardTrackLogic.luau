--!strict
-- Pure: timed reward track unlock times + display rows + claim order.

local MutationDatabase
local RewardTimerLogic
local RewardTrackDatabase
if script and script.Parent then
    MutationDatabase = require(script.Parent.Parent.data.MutationDatabase)
    RewardTimerLogic = require(script.Parent.RewardTimerLogic)
    RewardTrackDatabase = require(script.Parent.Parent.data.RewardTrackDatabase)
else
    MutationDatabase = require("../data/MutationDatabase")
    RewardTimerLogic = require("./RewardTimerLogic")
    RewardTrackDatabase = require("../data/RewardTrackDatabase")
end

export type TrackItem = {
    id: string,
    index: number,
    kind: string,
    rewardType: string,
    unlockAt: number,
    coins: number?,
    mutation: string?,
    caseLabel: string?,
    boxModelName: string?,
}

local RewardTrackLogic = {}

function RewardTrackLogic.offsetSec(offsetMin: number): number
    return math.max(0, math.floor(offsetMin)) * 60
end

function RewardTrackLogic.unlockAt(trackStartedAt: number, offsetMin: number): number
    return math.floor(trackStartedAt) + RewardTrackLogic.offsetSec(offsetMin)
end

function RewardTrackLogic.caseLabel(mutation: string): string
    local def = MutationDatabase.get(mutation)
    local name = if def then def.displayName else mutation
    return name .. " Case"
end

function RewardTrackLogic.buildItems(trackStartedAt: number): { TrackItem }
    local list: { TrackItem } = {}
    for i, slot in RewardTrackDatabase.slots() do
        local mutation = slot.mutation
        local caseLabel: string? = nil
        local boxModelName: string? = nil
        if slot.rewardType == "case" and typeof(mutation) == "string" then
            caseLabel = RewardTrackLogic.caseLabel(mutation)
            boxModelName = RewardTrackDatabase.caseBoxModelName(mutation)
        end
        table.insert(list, {
            id = slot.id,
            index = i,
            kind = slot.kind,
            rewardType = slot.rewardType,
            unlockAt = RewardTrackLogic.unlockAt(trackStartedAt, slot.offsetMin),
            coins = slot.coins,
            mutation = mutation,
            caseLabel = caseLabel,
            boxModelName = boxModelName,
        })
    end
    return list
end

function RewardTrackLogic.getSlot(rewardId: string): RewardTrackDatabase.SlotDef?
    for _, slot in RewardTrackDatabase.slots() do
        if slot.id == rewardId then
            return slot
        end
    end
    return nil
end

--- Sequential: only first unclaimed unlocked slot may be claimed.
function RewardTrackLogic.canClaim(
    rewardId: string,
    trackStartedAt: number,
    claimedIds: { string },
    now: number
): (boolean, string?)
    local claimedSet: { [string]: boolean } = {}
    for _, id in claimedIds do
        claimedSet[id] = true
    end
    local items = RewardTrackLogic.buildItems(trackStartedAt)
    local claimRows = {}
    for _, item in items do
        table.insert(claimRows, {
            claimed = claimedSet[item.id] == true,
            unlockAt = item.unlockAt,
        })
    end
    local idx = RewardTimerLogic.firstClaimableIndex(claimRows, now)
    if idx == nil then
        return false, "nothing_claimable"
    end
    if items[idx].id ~= rewardId then
        return false, "out_of_order"
    end
    return true, nil
end

return RewardTrackLogic
