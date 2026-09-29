--!strict
-- Pure Index catalog. Cards follow HeroDatabase; unlocks are max owned tier.

local FarmLogic
local HeroDatabase
local HeroLogic
local IndexDatabase
if script and script.Parent then
    FarmLogic = require(script.Parent.FarmLogic)
    HeroDatabase = require(script.Parent.Parent.data.HeroDatabase)
    HeroLogic = require(script.Parent.HeroLogic)
    IndexDatabase = require(script.Parent.Parent.data.IndexDatabase)
else
    FarmLogic = require("./FarmLogic")
    HeroDatabase = require("../data/HeroDatabase")
    HeroLogic = require("./HeroLogic")
    IndexDatabase = require("../data/IndexDatabase")
end

export type Card = {
    id: string,
    name: string,
    count: number,
    countLabel: string,
    unlocked: boolean,
    modelName: string,
    tier: number,
}

local IndexLogic = {}

function IndexLogic.columnCount(): number
    return IndexDatabase.COLUMNS
end

function IndexLogic.rememberTiers(indexMaxTier: number?, units: { number }): number
    return HeroLogic.rememberTiers(indexMaxTier, units)
end

function IndexLogic.cards(indexMaxTier: number?): { Card }
    local unlockedMax = math.max(0, math.floor(indexMaxTier or 0))
    local names = HeroDatabase.MODEL_NAMES
    local cards: { Card } = table.create(#names)
    for tier = 1, #names do
        local modelName = names[tier]
        local unlocked = tier <= unlockedMax
        local count = FarmLogic.tierBaseValue(tier)
        cards[tier] = {
            id = HeroLogic.slugId(modelName),
            name = HeroLogic.displayName(modelName),
            count = count,
            countLabel = if unlocked then tostring(count) else IndexDatabase.LOCKED_POINTS,
            unlocked = unlocked,
            modelName = modelName,
            tier = tier,
        }
    end
    return cards
end

return IndexLogic
