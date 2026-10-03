--!strict
-- Index catalog: every hero × Normal + each mutation. Pure keys / unlock.

local ContainerLogic
local HeroCatalog
local MutationDatabase
local RarityDatabase
if script and script.Parent then
    ContainerLogic = require(script.Parent.ContainerLogic)
    HeroCatalog = require(script.Parent.Parent.data.HeroCatalog)
    MutationDatabase = require(script.Parent.Parent.data.MutationDatabase)
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
else
    ContainerLogic = require("./ContainerLogic")
    HeroCatalog = require("../data/HeroCatalog")
    MutationDatabase = require("../data/MutationDatabase")
    RarityDatabase = require("../data/RarityDatabase")
end

export type IndexTier = "normal" | "golden" | "diamond" | "galaxy" | "secret" | "prismatic"

export type IndexEntry = {
    id: string,
    heroId: string,
    name: string,
    rarity: string,
    rareText: string,
    tier: IndexTier,
    mutationText: string,
    incomePerMini: number,
    unlocked: boolean,
}

--- UI tab order: Normal first, then mutations. Prismatic omitted until ready
--- (Limited Dragon still grants prismatic mutation in-world).
local TIER_ORDER: { IndexTier } = {
    "normal",
    "golden",
    "diamond",
    "galaxy",
    "secret",
}

local IndexLogic = {}

function IndexLogic.tierOrder(): { IndexTier }
    return TIER_ORDER
end

function IndexLogic.findKey(heroId: string, mutationId: string?): string
    if typeof(heroId) ~= "string" or heroId == "" then
        return ""
    end
    if typeof(mutationId) == "string" and mutationId ~= "" then
        return heroId .. ":" .. mutationId
    end
    return heroId
end

function IndexLogic.toFoundSet(keys: { string }?): { [string]: boolean }
    local set: { [string]: boolean } = {}
    if keys == nil then
        return set
    end
    for _, key in keys do
        if typeof(key) == "string" and key ~= "" then
            set[key] = true
        end
    end
    return set
end

--- Append key if missing. Returns true when newly added.
function IndexLogic.addFound(found: { string }, heroId: string, mutationId: string?): boolean
    local key = IndexLogic.findKey(heroId, mutationId)
    if key == "" then
        return false
    end
    if table.find(found, key) ~= nil then
        return false
    end
    table.insert(found, key)
    return true
end

local function rareText(rarity: string): string
    if rarity == "" then
        return ""
    end
    return string.upper(string.sub(rarity, 1, 1)) .. string.sub(rarity, 2)
end

local function mutationLabel(tier: IndexTier): string
    if tier == "normal" then
        return "Normal"
    end
    local def = MutationDatabase.get(tier)
    return if def then def.displayName else tier
end

local function mutationIdsForTier(tier: IndexTier): { string }?
    if tier == "normal" then
        return nil
    end
    return { tier }
end

function IndexLogic.buildEntries(foundKeys: { string }?): { IndexEntry }
    local found = IndexLogic.toFoundSet(foundKeys)
    local list: { IndexEntry } = {}

    for _, tier in TIER_ORDER do
        local mutIds = mutationIdsForTier(tier)
        local mutText = mutationLabel(tier)
        for _, rarity in RarityDatabase.ordered() do
            for _, heroId in HeroCatalog.pool(rarity) do
                local key = IndexLogic.findKey(heroId, if tier == "normal" then nil else tier)
                table.insert(list, {
                    id = key,
                    heroId = heroId,
                    name = HeroCatalog.displayName(heroId),
                    rarity = rarity,
                    rareText = rareText(rarity),
                    tier = tier,
                    mutationText = mutText,
                    incomePerMini = ContainerLogic.incomePerMini(rarity, mutIds),
                    unlocked = found[key] == true,
                })
            end
        end
    end

    return list
end

--- Mark found from already-unpacked slots / inventory (migrate + soft launch).
function IndexLogic.backfillFromOwned(
    found: { string },
    slots: {
        {
            unpacked: boolean?,
            heroId: string?,
            mutations: { string }?,
        }?
    }?,
    inventory: {
        {
            unpacked: boolean?,
            heroId: string?,
            mutations: { string }?,
        }
    }?
): number
    local added = 0
    local function consider(item: { unpacked: boolean?, heroId: string?, mutations: { string }? }?)
        if item == nil or item.unpacked ~= true then
            return
        end
        local heroId = item.heroId
        if typeof(heroId) ~= "string" or heroId == "" then
            return
        end
        local muts = item.mutations
        local mutId: string? = nil
        if typeof(muts) == "table" and #muts > 0 and typeof(muts[1]) == "string" then
            mutId = muts[1]
        end
        if IndexLogic.addFound(found, heroId, mutId) then
            added += 1
        end
    end

    if slots then
        for _, slot in slots do
            consider(slot)
        end
    end
    if inventory then
        for _, item in inventory do
            consider(item)
        end
    end
    return added
end

return IndexLogic
