--!strict
-- Pure mutation + rarity rolls for stand offers. CI-tested.

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
    local names: { string } = {}
    for _, id in mutationIds do
        local def = MutationDatabase.get(id)
        table.insert(names, if def then def.displayName else id)
    end
    return table.concat(names, "-")
end

function MutationLogic.pickRarity(rng01: number): RarityId
    local total = 0
    for _, id in RarityDatabase.ordered() do
        local e = RarityDatabase.ById[id]
        total += e.weight
    end
    local roll = math.clamp(rng01, 0, 0.999999) * total
    local acc = 0
    for _, id in RarityDatabase.ordered() do
        local e = RarityDatabase.ById[id]
        acc += e.weight
        if roll < acc then
            return id
        end
    end
    return "common"
end

local function pickMutationId(rng01: number, owned: { string }): string?
    if #owned >= MutationDatabase.MAX_STACKS then
        return nil
    end
    local pool = MutationDatabase.all()
    local eligible = {}
    local total = 0
    for _, m in pool do
        local taken = false
        for _, id in owned do
            if id == m.id then
                taken = true
                break
            end
        end
        if not taken then
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

-- Chance fraction of rarity.mutationChance so offers stay special.
local OFFER_MUTATION_FACTOR = 0.45

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
    local id = pickMutationId(rngPick, {})
    if id then
        return { id }
    end
    return {}
end

-- Optional second stack during unpack (end roll).
function MutationLogic.rollUnpackMutation(
    rarity: string,
    owned: { string },
    rngChance: number,
    rngPick: number
): string?
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return nil
    end
    if rngChance >= entry.mutationChance then
        return nil
    end
    return pickMutationId(rngPick, owned)
end

return MutationLogic
