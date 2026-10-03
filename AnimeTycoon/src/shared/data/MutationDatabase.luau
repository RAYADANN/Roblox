--!strict
-- Named mutations on containers/heroes. UI reads displayName.
-- Align with GameAssets.Mutations (shine variants in MutationShineDatabase).

export type MutationDef = {
    id: string,
    displayName: string,
    incomeMult: number,
    weight: number,
}

local MUTATIONS: { MutationDef } = {
    { id = "secret", displayName = "Secret", incomeMult = 1.25, weight = 18 },
    { id = "galaxy", displayName = "Galaxy", incomeMult = 1.35, weight = 14 },
    { id = "diamond", displayName = "Diamond", incomeMult = 1.4, weight = 12 },
    -- Disabled for stand rolls / Index until FX ready. Limited Dragon Cannelloni still uses id.
    { id = "prismatic", displayName = "Prismatic", incomeMult = 1.55, weight = 0 },
    { id = "golden", displayName = "Golden", incomeMult = 1.35, weight = 16 },
}

local byId: { [string]: MutationDef } = {}
for _, m in MUTATIONS do
    byId[m.id] = m
end

local MutationDatabase = {}

MutationDatabase.MAX_STACKS = 1

function MutationDatabase.get(id: string): MutationDef?
    return byId[id]
end

function MutationDatabase.all(): { MutationDef }
    return MUTATIONS
end

--- Mutations that can appear on stand rolls (weight > 0).
function MutationDatabase.rollPool(): { MutationDef }
    local out: { MutationDef } = {}
    for _, m in MUTATIONS do
        if m.weight > 0 then
            table.insert(out, m)
        end
    end
    return out
end

--- Mutation ids shown as Index tabs (excludes disabled / weight 0).
function MutationDatabase.indexIds(): { string }
    local out: { string } = {}
    for _, m in MUTATIONS do
        if m.weight > 0 then
            table.insert(out, m.id)
        end
    end
    return out
end

return MutationDatabase
