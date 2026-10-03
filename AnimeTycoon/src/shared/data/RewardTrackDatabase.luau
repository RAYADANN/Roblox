--!strict
-- Timed Rewards track: 12 slots, cumulative minutes from track start.

export type RewardType = "money" | "case"

export type SlotDef = {
    id: string,
    --- Minutes from trackStartedAt.
    offsetMin: number,
    rewardType: RewardType,
    --- Soft currency when rewardType == money.
    coins: number?,
    --- Mutation id for case (golden / diamond / galaxy).
    mutation: string?,
    --- Card chrome: money | golden | diamond | galaxy.
    kind: string,
}

--[[
  #3 Golden case, #5 money, #6 Diamond, #10 Galaxy, #11 Diamond, #12 Galaxy.
  Rest = money. Offsets: 0 / 5 / 10 / 15 / 25 / 35 / 45 / 60 / 75 / 90 / 105 / 120.
]]
local SLOTS: { SlotDef } = {
    {
        id = "r1",
        offsetMin = 0,
        rewardType = "money",
        coins = 50_000,
        kind = "money",
    },
    {
        id = "r2",
        offsetMin = 5,
        rewardType = "money",
        coins = 120_000,
        kind = "money",
    },
    {
        id = "r3",
        offsetMin = 10,
        rewardType = "case",
        mutation = "golden",
        kind = "golden",
    },
    {
        id = "r4",
        offsetMin = 15,
        rewardType = "money",
        coins = 280_000,
        kind = "money",
    },
    {
        id = "r5",
        offsetMin = 25,
        rewardType = "money",
        coins = 450_000,
        kind = "money",
    },
    {
        id = "r6",
        offsetMin = 35,
        rewardType = "case",
        mutation = "diamond",
        kind = "diamond",
    },
    {
        id = "r7",
        offsetMin = 45,
        rewardType = "money",
        coins = 750_000,
        kind = "money",
    },
    {
        id = "r8",
        offsetMin = 60,
        rewardType = "money",
        coins = 1_100_000,
        kind = "money",
    },
    {
        id = "r9",
        offsetMin = 75,
        rewardType = "money",
        coins = 1_600_000,
        kind = "money",
    },
    {
        id = "r10",
        offsetMin = 90,
        rewardType = "case",
        mutation = "galaxy",
        kind = "galaxy",
    },
    {
        id = "r11",
        offsetMin = 105,
        rewardType = "case",
        mutation = "diamond",
        kind = "diamond",
    },
    {
        id = "r12",
        offsetMin = 120,
        rewardType = "case",
        mutation = "galaxy",
        kind = "galaxy",
    },
}

--- Box mesh under GameAssets.Boxes for case cards (Diamond tier for all mutations).
local CASE_BOX_BY_MUTATION: { [string]: string } = {
    golden = "Diamond_Topaz",
    diamond = "Diamond_Sapphire",
    galaxy = "Diamond_Obsidian",
}

local RewardTrackDatabase = {}

function RewardTrackDatabase.slots(): { SlotDef }
    return SLOTS
end

function RewardTrackDatabase.caseBoxModelName(mutation: string): string
    return CASE_BOX_BY_MUTATION[mutation] or "Diamond_Topaz"
end

function RewardTrackDatabase.skipRobuxPrice(): number
    local ProductIds = if script and script.Parent
        then require(script.Parent.ProductIds)
        else require("./ProductIds")
    local price = (ProductIds :: any).SkipAllRewardsRobuxPrice
    return if typeof(price) == "number" then price else 119
end

--- Max timer offset (minutes) — used by Skip All to unlock the full track.
function RewardTrackDatabase.maxOffsetMin(): number
    local maxMin = 0
    for _, slot in SLOTS do
        if slot.offsetMin > maxMin then
            maxMin = slot.offsetMin
        end
    end
    return maxMin
end

return RewardTrackDatabase
