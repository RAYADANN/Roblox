--!strict
-- Named mutations on containers/heroes. UI reads displayName.

export type MutationDef = {
    id: string,
    displayName: string,
    incomeMult: number,
    weight: number,
}

local MUTATIONS: { MutationDef } = {
    { id = "golden", displayName = "Golden", incomeMult = 1.35, weight = 20 },
    { id = "neon", displayName = "Neon", incomeMult = 1.25, weight = 18 },
    { id = "spark", displayName = "Spark", incomeMult = 1.2, weight = 16 },
    { id = "prism", displayName = "Prism", incomeMult = 1.4, weight = 12 },
    { id = "shadow", displayName = "Shadow", incomeMult = 1.3, weight = 12 },
    { id = "volt", displayName = "Volt", incomeMult = 1.5, weight = 8 },
    { id = "demon", displayName = "Demon", incomeMult = 1.6, weight = 6 },
}

local byId: { [string]: MutationDef } = {}
for _, m in MUTATIONS do
    byId[m.id] = m
end

local MutationDatabase = {}

MutationDatabase.MAX_STACKS = 2

function MutationDatabase.get(id: string): MutationDef?
    return byId[id]
end

function MutationDatabase.all(): { MutationDef }
    return MUTATIONS
end

return MutationDatabase
