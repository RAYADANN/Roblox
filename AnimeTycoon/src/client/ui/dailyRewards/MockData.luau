--!strict
-- Mock: дни 1–2 claimed, 3 claimable, 4–7 locked (как на референсе).

local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

local MockData = {}

function MockData.backgroundFor(kind: types.DayKind): string
    if kind == "money" then
        return assets.cardMoney
    elseif kind == "smalltime" then
        return assets.cardSmalltime
    elseif kind == "secret" then
        return assets.cardSecret
    elseif kind == "singularity" then
        return assets.cardSingularity
    elseif kind == "timer" then
        return assets.cardTimer
    elseif kind == "admin" then
        return assets.cardAdmin
    elseif kind == "super" then
        return assets.cardSuper
    end
    return assets.cardMoney
end

function MockData.items(): { types.DailyRewardItem }
    return {
        {
            id = "d1",
            day = 1,
            kind = "money",
            valueText = "$56,000",
            claimed = true,
        },
        {
            id = "d2",
            day = 2,
            kind = "smalltime",
            valueText = "30m Time Skip",
            claimed = true,
        },
        {
            id = "d3",
            day = 3,
            kind = "secret",
            valueText = "Chrono Crystal",
            claimed = false,
        },
        {
            id = "d4",
            day = 4,
            kind = "singularity",
            valueText = "Singularity Ore",
            claimed = false,
        },
        {
            id = "d5",
            day = 5,
            kind = "timer",
            valueText = "2h Time Skip",
            claimed = false,
        },
        {
            id = "d6",
            day = 6,
            kind = "admin",
            valueText = "Supernova Ore",
            claimed = false,
        },
        {
            id = "d7",
            day = 7,
            kind = "super",
            valueText = "Devils Growth Gem",
            claimed = false,
            opText = "OP!",
        },
    }
end

return MockData
