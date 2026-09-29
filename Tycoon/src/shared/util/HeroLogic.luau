--!strict
-- Pure hero catalog helpers. CI-tested (Lune).

local HeroDatabase
if script and script.Parent then
    HeroDatabase = require(script.Parent.Parent.data.HeroDatabase)
else
    HeroDatabase = require("../data/HeroDatabase")
end

local HeroLogic = {}

function HeroLogic.count(): number
    return #HeroDatabase.MODEL_NAMES
end

function HeroLogic.modelNameForTier(tier: number): string
    local names = HeroDatabase.MODEL_NAMES
    local n = #names
    if n == 0 then
        return "Ninja"
    end
    local t = math.max(1, math.floor(tier))
    if t > n then
        return names[n]
    end
    return names[t]
end

function HeroLogic.displayName(modelName: string): string
    return string.upper(modelName)
end

function HeroLogic.slugId(modelName: string): string
    local slug = string.lower(modelName)
    slug = string.gsub(slug, "[^a-z0-9]+", "_")
    slug = string.gsub(slug, "^_+", "")
    slug = string.gsub(slug, "_+$", "")
    if slug == "" then
        return "hero"
    end
    return slug
end

function HeroLogic.rememberTiers(indexMaxTier: number?, units: { number }): number
    local maxTier = math.max(0, math.floor(indexMaxTier or 0))
    for _, tier in units do
        if tier > maxTier then
            maxTier = tier
        end
    end
    return maxTier
end

return HeroLogic
