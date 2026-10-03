--!strict
-- Rewards cards from RewardTrackDatabase (12 slots).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formatters = require(script.Parent.Parent.util.Formatters)
local RewardTrackDatabase =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("data").RewardTrackDatabase)
local RewardTrackLogic =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("util").RewardTrackLogic)
local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

local MockData = {}

function MockData.backgroundFor(kind: types.RewardKind): string
    if kind == "golden" then
        return assets.cardGolden
    elseif kind == "diamond" then
        return assets.cardDiamond
    elseif kind == "galaxy" then
        return assets.cardGalaxy
    end
    return assets.cardMoney
end

local function nowSec(): number
    local ok, t = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    if ok and typeof(t) == "number" then
        return math.floor(t)
    end
    return os.time()
end

export type ItemsOpts = {
    --- Unix start of track. Default: now (first slot claimable).
    trackStartedAt: number?,
    --- Mark first N slots claimed for story/demo.
    claimedCount: number?,
    --- Explicit claimed reward ids from server session.
    claimedIds: { string }?,
}

function MockData.items(opts: ItemsOpts?): { types.RewardItem }
    local started = if opts and opts.trackStartedAt then opts.trackStartedAt else nowSec()
    local claimedCount = if opts and opts.claimedCount then opts.claimedCount else 0
    local claimedSet: { [string]: boolean } = {}
    if opts and opts.claimedIds then
        for _, id in opts.claimedIds do
            claimedSet[id] = true
        end
    end
    local rows = RewardTrackLogic.buildItems(started)
    local list: { types.RewardItem } = {}
    for i, row in rows do
        local valueText: string
        if row.rewardType == "case" then
            valueText = row.caseLabel or "Case"
        else
            valueText = Formatters.money(row.coins or 0)
        end
        local claimed = claimedSet[row.id] == true or i <= claimedCount
        table.insert(list, {
            id = row.id,
            kind = row.kind :: types.RewardKind,
            valueText = valueText,
            unlockAt = row.unlockAt,
            claimed = claimed,
            rewardType = row.rewardType :: any,
            mutation = row.mutation,
            boxModelName = row.boxModelName,
            coins = row.coins,
        })
    end
    return list
end

function MockData.skipPrice(): number
    return RewardTrackDatabase.skipRobuxPrice()
end

return MockData
