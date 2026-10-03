--!strict
-- Mutation → world FX source under ReplicatedStorage.GameAssets.MutationFx.
-- effectModelName: child of MutationFx
-- FX part is cloned onto the hero (not used to swap box mesh by rarity).

export type MutationVisualDef = {
    mutationId: string,
    effectModelName: string, -- child of GameAssets.MutationFx
    effectPartNames: { string }, -- tried in order
}

local DEFS: { MutationVisualDef } = {
    {
        mutationId = "golden",
        effectModelName = "Gold",
        effectPartNames = { "JamVfxinstance", "VfxInstance" },
    },
    {
        mutationId = "diamond",
        effectModelName = "Diamond",
        effectPartNames = { "tralalafxpart", "VfxInstance" },
    },
    {
        mutationId = "galaxy",
        effectModelName = "Galaxy",
        effectPartNames = { "VfxInstance" },
    },
    {
        mutationId = "secret",
        effectModelName = "SecretBox",
        effectPartNames = { "VfxInstance" },
    },
    {
        mutationId = "prismatic",
        effectModelName = "Galaxy",
        effectPartNames = { "VfxInstance" },
    },
}

local byId: { [string]: MutationVisualDef } = {}
for _, d in DEFS do
    byId[d.mutationId] = d
end

local MutationVisualDatabase = {}

--- Box FX slightly larger than mesh so particles read on small containers.
MutationVisualDatabase.BOX_FX_SCALE = 1.35

--- Hero FX: scale VfxInstance to visible mesh max-axis × this, center on mesh (ignore Root*).
--- Same path as Workspace.Preview_GalaxyAll.
MutationVisualDatabase.HERO_FX_SCALE = 1.1

function MutationVisualDatabase.get(mutationId: string): MutationVisualDef?
    return byId[mutationId]
end

--- Prefer last (highest) mutation stack for the attached FX.
function MutationVisualDatabase.resolveFromStack(mutationIds: { string }?): MutationVisualDef?
    if not mutationIds or #mutationIds == 0 then
        return nil
    end
    for i = #mutationIds, 1, -1 do
        local def = byId[mutationIds[i]]
        if def then
            return def
        end
    end
    return nil
end

function MutationVisualDatabase.all(): { MutationVisualDef }
    return DEFS
end

return MutationVisualDatabase
