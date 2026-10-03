--!strict
-- Placed-hero level. Pure. Level 1 matches today's payout; each step is +15%
-- before rounding, and the coin cost is the extra coins/sec times a payback
-- that grows 15% per level. A maxed common out-earns a fresh mythic.

local Constants
local ContainerLogic
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
    ContainerLogic = require(script.Parent.ContainerLogic)
else
    Constants = require("../data/Constants")
    ContainerLogic = require("./ContainerLogic")
end

export type IncomeItem = {
    rarity: string,
    mutations: { string }?,
    baseIncome: number?,
    level: number?,
    incomeRate: number?,
    unpacked: boolean?,
}

local HeroLevelLogic = {}

function HeroLevelLogic.maxLevel(): number
    return Constants.HERO_MAX_LEVEL
end

function HeroLevelLogic.normalize(level: number?): number
    local n = math.floor(tonumber(level) or 1)
    if n < 1 then
        n = 1
    end
    if n > Constants.HERO_MAX_LEVEL then
        n = Constants.HERO_MAX_LEVEL
    end
    return n
end

function HeroLevelLogic.isMax(level: number?): boolean
    return HeroLevelLogic.normalize(level) >= Constants.HERO_MAX_LEVEL
end

--- 1 at level 1. Compounds by HERO_LEVEL_GROWTH each level after that.
function HeroLevelLogic.multiplier(level: number?): number
    local n = HeroLevelLogic.normalize(level)
    return Constants.HERO_LEVEL_GROWTH ^ (n - 1)
end

--- Coins per mini at this level. `basePerMini` is the level-1 payout.
function HeroLevelLogic.income(basePerMini: number, level: number?): number
    if basePerMini <= 0 then
        return 0
    end
    return math.max(1, math.floor(basePerMini * HeroLevelLogic.multiplier(level) + 0.5))
end

--- Level-1 coins per mini. Rarity formula wins; stored base covers Limited / unknown rarity.
function HeroLevelLogic.basePerMini(
    rarity: string,
    mutationIds: { string }?,
    storedBase: number?
): number
    local fromRarity = ContainerLogic.incomePerMini(rarity, mutationIds)
    if fromRarity > 0 then
        return fromRarity
    end
    local stored = if typeof(storedBase) == "number" then storedBase else 0
    if stored > 0 then
        return stored
    end
    return 0
end

--- Coins to buy the next level. Nil at max or when the hero has no income.
function HeroLevelLogic.upgradeCost(
    basePerMini: number,
    intervalSec: number,
    currentLevel: number?
): number?
    local level = HeroLevelLogic.normalize(currentLevel)
    if level >= Constants.HERO_MAX_LEVEL or basePerMini <= 0 then
        return nil
    end
    local interval = math.max(0.05, intervalSec)
    local delta = HeroLevelLogic.income(basePerMini, level + 1)
        - HeroLevelLogic.income(basePerMini, level)
    local deltaPerSec = math.max(0, delta) / interval
    local targetSec = Constants.HERO_LEVEL_PAYBACK_SEC
        * Constants.HERO_LEVEL_PAYBACK_GROWTH ^ (level - 1)
    return math.max(1, math.floor(deltaPerSec * targetSec + 0.5))
end

--- Write `level` and leveled `incomeRate` on an opened hero. Sealed boxes are left alone.
function HeroLevelLogic.syncIncome(item: IncomeItem)
    if item.unpacked ~= true then
        return
    end
    local level = HeroLevelLogic.normalize(item.level)
    item.level = level
    local base = HeroLevelLogic.basePerMini(item.rarity, item.mutations, item.baseIncome)
    if base > 0 then
        item.incomeRate = HeroLevelLogic.income(base, level)
    end
end

return HeroLevelLogic
