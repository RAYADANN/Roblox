--!strict
-- Pure mutation + rarity rolls for stand offers. CI-tested.
-- Mutations: at most ONE, only from buying a mutated offer (never on unpack).

local RarityDatabase
local MutationDatabase
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
    MutationDatabase = require(script.Parent.Parent.data.MutationDatabase)
else
    RarityDatabase = require("../data/RarityDatabase")
    MutationDatabase = require("../data/MutationDatabase")
end

export type RarityId = RarityDatabase.RarityId

local MutationLogic = {}

function MutationLogic.formatLabel(mutationIds: { string }): string
    if #mutationIds == 0 then
        return ""
    end
    -- Single mutation only — take first known id.
    local id = mutationIds[1]
    local def = MutationDatabase.get(id)
    return if def then def.displayName else id
end

--- Clamp profile/offer stacks to at most one mutation.
function MutationLogic.normalizeStack(mutationIds: { string }?): { string }
    if not mutationIds or #mutationIds == 0 then
        return {}
    end
    local id = mutationIds[1]
    if typeof(id) == "string" and id ~= "" and MutationDatabase.get(id) then
        return { id }
    end
    for _, candidate in mutationIds do
        if typeof(candidate) == "string" and MutationDatabase.get(candidate) then
            return { candidate }
        end
    end
    return {}
end

function MutationLogic.pickRarity(rng01: number, luckBias: number?, luckMult: number?): RarityId
    local bias = math.max(0, luckBias or 0)
    local rareMult = math.max(1, luckMult or 1)
    local total = 0
    local weighted: { { id: RarityId, w: number } } = {}
    local order = RarityDatabase.ordered()
    for i, id in order do
        local e = RarityDatabase.ById[id]
        -- Higher index = rarer; luckBias scales rarer weights up; pass mult boosts non-common.
        local w = e.weight * (1 + bias * (i - 1))
        if i > 1 then
            w *= rareMult
        end
        table.insert(weighted, { id = id, w = w })
        total += w
    end
    local roll = math.clamp(rng01, 0, 0.999999) * total
    local acc = 0
    for _, row in weighted do
        acc += row.w
        if roll < acc then
            return row.id
        end
    end
    return "common"
end

local function pickMutationId(rng01: number): string?
    local pool = MutationDatabase.rollPool()
    local total = 0
    for _, m in pool do
        total += m.weight
    end
    if total <= 0 or #pool == 0 then
        return nil
    end
    local roll = math.clamp(rng01, 0, 0.999999) * total
    local acc = 0
    for _, m in pool do
        acc += m.weight
        if roll < acc then
            return m.id
        end
    end
    return pool[#pool].id
end

-- Chance fraction of rarity.mutationChance so offers stay special.
local OFFER_MUTATION_FACTOR = 0.45

--- At most one mutation, rolled when the offer is created (buy carries it).
function MutationLogic.rollOfferMutations(
    rarity: string,
    rngChance: number,
    rngPick: number
): { string }
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return {}
    end
    if rngChance >= entry.mutationChance * OFFER_MUTATION_FACTOR then
        return {}
    end
    local id = pickMutationId(rngPick)
    if id then
        return { id }
    end
    return {}
end

return MutationLogic
