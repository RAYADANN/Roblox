--!strict
-- 3×4: green=Money, blue=Golden, purple=Diamond, yellow=Galaxy.
-- unlockAt — реальные unix-таймеры от «сейчас».

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

--- offsetsSec: отрицательный = уже открыт; claimed задаётся отдельно.
function MockData.items(now: number?): { types.RewardItem }
    local t = now or nowSec()
    return {
        -- Row 1
        {
            id = "r1",
            kind = "money",
            valueText = "$320,000",
            unlockAt = t - 600,
            claimed = true,
        },
        {
            id = "r2",
            kind = "money",
            valueText = "$650,000",
            unlockAt = t - 300,
            claimed = true,
        },
        {
            id = "r3",
            kind = "golden",
            valueText = "Sulfur Crystal",
            unlockAt = t, -- сразу claimable после двух CLAIMED
        },
        {
            id = "r4",
            kind = "money",
            valueText = "$1,300,000",
            unlockAt = t + 886,
        },
        -- Row 2
        {
            id = "r5",
            kind = "galaxy",
            valueText = "Gold Ore",
            unlockAt = t + 1786,
        },
        {
            id = "r6",
            kind = "money",
            valueText = "$1,900,000",
            unlockAt = t + 2986,
        },
        {
            id = "r7",
            kind = "money",
            valueText = "$2,600,000",
            unlockAt = t + 3586,
        },
        {
            id = "r8",
            kind = "diamond",
            valueText = "Amethyst Ore",
            unlockAt = t + 4186,
        },
        -- Row 3
        {
            id = "r9",
            kind = "galaxy",
            valueText = "Sunstone Ore",
            unlockAt = t + 4786,
        },
        {
            id = "r10",
            kind = "money",
            valueText = "$3,200,000",
            unlockAt = t + 5386,
        },
        {
            id = "r11",
            kind = "money",
            valueText = "$3,900,000",
            unlockAt = t + 5986,
        },
        {
            id = "r12",
            kind = "golden",
            valueText = "Lunar Crystal",
            unlockAt = t + 6586,
        },
    }
end

function MockData.skipPrice(): number
    return 119
end

return MockData
