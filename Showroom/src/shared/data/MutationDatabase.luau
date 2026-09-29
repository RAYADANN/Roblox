--!strict
-- Named mutations. Growth vs lonely (no visitors). UI reads displayName.

export type MutationKind = "growth" | "lonely"

export type MutationDef = {
    id: string,
    displayName: string,
    kind: MutationKind,
    weight: number,
}

local MUTATIONS: { MutationDef } = {
    { id = "spark", displayName = "Spark", kind = "growth", weight = 20 },
    { id = "neon", displayName = "Neon", kind = "growth", weight = 16 },
    { id = "gloss", displayName = "Gloss", kind = "growth", weight = 16 },
    { id = "prism", displayName = "Prism", kind = "growth", weight = 12 },
    { id = "bloom", displayName = "Bloom", kind = "growth", weight = 12 },
    { id = "echo", displayName = "Echo", kind = "growth", weight = 10 },
    -- Scale-only (2× Large model); no Workspace particle template.
    { id = "giant", displayName = "Giant", kind = "growth", weight = 8 },
    { id = "volt", displayName = "Volt", kind = "growth", weight = 6 },
    -- Only when NPCs refuse to approach.
    { id = "forsaken", displayName = "Forsaken", kind = "lonely", weight = 34 },
    { id = "hollow", displayName = "Hollow", kind = "lonely", weight = 33 },
    { id = "ghosted", displayName = "Ghosted", kind = "lonely", weight = 33 },
}

local byId: { [string]: MutationDef } = {}
for _, m in MUTATIONS do
    byId[m.id] = m
end

local MutationDatabase = {}

MutationDatabase.MAX_STACKS = 3
MutationDatabase.CELEBRATE_SEC = 4
MutationDatabase.EVOLVE_CELEBRATE_SEC = 7

function MutationDatabase.get(id: string): MutationDef?
    return byId[id]
end

function MutationDatabase.all(): { MutationDef }
    return MUTATIONS
end

function MutationDatabase.byKind(kind: MutationKind): { MutationDef }
    local out: { MutationDef } = {}
    for _, m in MUTATIONS do
        if m.kind == kind then
            table.insert(out, m)
        end
    end
    return out
end

return MutationDatabase
