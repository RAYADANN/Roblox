--!strict
-- Pure mutation roll + named stacks + lonely (no NPC) path. CI-tested.

local RarityDatabase
local ExhibitCatalog
local MutationDatabase
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
    ExhibitCatalog = require(script.Parent.Parent.data.ExhibitCatalog)
    MutationDatabase = require(script.Parent.Parent.data.MutationDatabase)
else
    RarityDatabase = require("../data/RarityDatabase")
    ExhibitCatalog = require("../data/ExhibitCatalog")
    MutationDatabase = require("../data/MutationDatabase")
end

export type RarityId = RarityDatabase.RarityId

local MutationLogic = {}

local function hasId(owned: { string }, id: string): boolean
    for _, x in owned do
        if x == id then
            return true
        end
    end
    return false
end

local function pickWeighted(
    pool: { MutationDatabase.MutationDef },
    owned: { string },
    rng01: number
): string?
    local eligible: { MutationDatabase.MutationDef } = {}
    local total = 0
    for _, m in pool do
        if not hasId(owned, m.id) then
            table.insert(eligible, m)
            total += m.weight
        end
    end
    if total <= 0 or #eligible == 0 then
        return nil
    end
    local roll = math.clamp(rng01, 0, 0.999999) * total
    local acc = 0
    for _, m in eligible do
        acc += m.weight
        if roll < acc then
            return m.id
        end
    end
    return eligible[#eligible].id
end

function MutationLogic.formatLabel(mutationIds: { string }): string
    if #mutationIds == 0 then
        return ""
    end
    local names: { string } = {}
    for _, id in mutationIds do
        local def = MutationDatabase.get(id)
        table.insert(names, if def then def.displayName else id)
    end
    return table.concat(names, "-")
end

-- Inverse of formatLabel for client visuals (ids match lowercased displayName).
function MutationLogic.idsFromLabel(label: string?): { string }
    local out: { string } = {}
    if typeof(label) ~= "string" or label == "" then
        return out
    end
    for _, seg in string.split(label, "-") do
        if seg ~= "" then
            table.insert(out, string.lower(seg))
        end
    end
    return out
end

function MutationLogic.pickGrowthId(owned: { string }, rng01: number): string?
    if #owned >= MutationDatabase.MAX_STACKS then
        return nil
    end
    return pickWeighted(MutationDatabase.byKind("growth"), owned, rng01)
end

function MutationLogic.pickLonelyId(owned: { string }, rng01: number): string?
    if #owned >= MutationDatabase.MAX_STACKS then
        return nil
    end
    return pickWeighted(MutationDatabase.byKind("lonely"), owned, rng01)
end

function MutationLogic.hasLonely(owned: { string }): boolean
    for _, id in owned do
        local def = MutationDatabase.get(id)
        if def and def.kind == "lonely" then
            return true
        end
    end
    return false
end

local EGG_MUTATION_FACTOR = 0.4

--[[
  Egg / offer starting mutations (growth only). Chance is a fraction of
  end-of-growth mutationChance so eggs stay special, not common.
]]
function MutationLogic.rollEggMutations(
    rarity: string,
    rngChance: number,
    rngPick: number
): { string }
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return {}
    end
    local chance = entry.mutationChance * EGG_MUTATION_FACTOR
    if rngChance >= chance then
        return {}
    end
    local id = MutationLogic.pickGrowthId({}, rngPick)
    if id then
        return { id }
    end
    return {}
end

-- One-shot chance (end-of-growth fallback).
function MutationLogic.shouldMutate(rarity: string, rng01: number): boolean
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return false
    end
    return rng01 < entry.mutationChance
end

function MutationLogic.shouldAvoidNpcs(rarity: string, rng01: number): boolean
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return false
    end
    return rng01 < entry.npcAvoidChance
end

--[[
  Per-tick roll while growing. Approximates P(at least one success over duration)
  ≈ mutationChance via hazard.
]]
function MutationLogic.rollDuringGrowth(
    rarity: string,
    dt: number,
    alreadyMutated: boolean,
    rng01: number
): boolean
    local entry = RarityDatabase.get(rarity)
    if not entry or dt <= 0 then
        return false
    end
    local duration = entry.evolveDurationSec
    if duration <= 0 then
        return MutationLogic.shouldMutate(rarity, rng01)
    end
    local target = entry.mutationChance
    if alreadyMutated then
        target = target * 0.55
    end
    local survival = (1 - target) ^ (dt / duration)
    local p = 1 - survival
    return rng01 < p
end

-- Lonely mutation hazard when nobody visits.
function MutationLogic.rollLonelyDuringGrowth(
    rarity: string,
    dt: number,
    alreadyHasLonely: boolean,
    rng01: number
): boolean
    local entry = RarityDatabase.get(rarity)
    if not entry or dt <= 0 or alreadyHasLonely then
        return false
    end
    local duration = entry.evolveDurationSec
    if duration <= 0 then
        return rng01 < entry.lonelyMutationChance
    end
    local target = entry.lonelyMutationChance
    local survival = (1 - target) ^ (dt / duration)
    return rng01 < (1 - survival)
end

function MutationLogic.pickRarity(rng01: number): RarityId
    local total = 0
    for _, id in RarityDatabase.ORDER do
        total += RarityDatabase.ById[id].weight
    end
    if total <= 0 then
        return "common"
    end
    local roll = math.clamp(rng01, 0, 0.999999) * total
    local acc = 0
    for _, id in RarityDatabase.ORDER do
        acc += RarityDatabase.ById[id].weight
        if roll < acc then
            return id
        end
    end
    return "legendary"
end

function MutationLogic.pickTemplate(rng01: number): string
    local list = ExhibitCatalog.TEMPLATES
    if #list == 0 then
        return "orb_teal"
    end
    local idx = math.floor(math.clamp(rng01, 0, 0.999999) * #list) + 1
    return list[idx].templateId
end

return MutationLogic
