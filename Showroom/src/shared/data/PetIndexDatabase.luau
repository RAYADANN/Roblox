--!strict
-- Index catalog: base pets per egg + evolution variants (scene models).

export type EvolutionDef = {
    id: string,
    name: string,
    modelName: string,
}

export type BasePetDef = {
    id: string,
    eggId: string,
    name: string,
    modelName: string,
    evolutions: { EvolutionDef },
}

-- Scene pets live under Workspace.Folder (cat / dog / fish / owl).
local PETS: { BasePetDef } = {
    {
        id = "cat",
        eggId = "domestic",
        name = "Cat",
        modelName = "cat",
        evolutions = {
            { id = "cat", name = "Cat", modelName = "cat" },
            { id = "cat_ember", name = "Ember Cat", modelName = "cat" },
            { id = "cat_frost", name = "Frost Cat", modelName = "cat" },
        },
    },
    {
        id = "dog",
        eggId = "domestic",
        name = "Dog",
        modelName = "dog",
        evolutions = {
            { id = "dog", name = "Dog", modelName = "dog" },
            { id = "dog_ember", name = "Ember Dog", modelName = "dog" },
            { id = "dog_shadow", name = "Shadow Dog", modelName = "dog" },
        },
    },
    {
        id = "owl",
        eggId = "forest",
        name = "Owl",
        modelName = "owl",
        evolutions = {
            { id = "owl", name = "Owl", modelName = "owl" },
            { id = "owl_moss", name = "Moss Owl", modelName = "owl" },
            { id = "owl_bloom", name = "Bloom Owl", modelName = "owl" },
        },
    },
    {
        id = "fish",
        eggId = "ice",
        name = "Fish",
        modelName = "fish",
        evolutions = {
            { id = "fish", name = "Fish", modelName = "fish" },
            { id = "fish_frost", name = "Frost Fish", modelName = "fish" },
            { id = "fish_crystal", name = "Crystal Fish", modelName = "fish" },
        },
    },
    -- Volcano egg: reuse scene pets as placeholders until dedicated meshes land.
    {
        id = "ember_cat",
        eggId = "volcano",
        name = "Ember Cat",
        modelName = "cat",
        evolutions = {
            { id = "ember_cat", name = "Ember Cat", modelName = "cat" },
            { id = "ember_cat_magma", name = "Magma Cat", modelName = "cat" },
        },
    },
    {
        id = "ash_dog",
        eggId = "volcano",
        name = "Ash Dog",
        modelName = "dog",
        evolutions = {
            { id = "ash_dog", name = "Ash Dog", modelName = "dog" },
            { id = "ash_dog_lava", name = "Lava Dog", modelName = "dog" },
        },
    },
}

local byId: { [string]: BasePetDef } = {}
local byEgg: { [string]: { BasePetDef } } = {}
for _, pet in PETS do
    byId[pet.id] = pet
    local list = byEgg[pet.eggId]
    if list == nil then
        list = {}
        byEgg[pet.eggId] = list
    end
    table.insert(list, pet)
end

local PetIndexDatabase = {
    PETS = PETS,
    byId = byId,
}

function PetIndexDatabase.get(id: string): BasePetDef?
    return byId[id]
end

function PetIndexDatabase.forEgg(eggId: string): { BasePetDef }
    return byEgg[eggId] or {}
end

return PetIndexDatabase
