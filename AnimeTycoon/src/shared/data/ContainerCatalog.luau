--!strict
-- Container (box) + hero template catalog. Meshes live in Workspace.

export type ContainerTemplate = {
    id: string,
    displayName: string,
    boxModelName: string, -- Workspace.Box1 / Box2 / Box3
    weight: number,
    heroPool: { string }, -- names under Demons Slayer Pack.Units
}

local TEMPLATES: { ContainerTemplate } = {
    {
        id = "box1",
        displayName = "Toy Crate",
        boxModelName = "Box1",
        weight = 40,
        heroPool = { "Tanjiro", "Nezuko", "Zenitsu", "Inosuke" },
    },
    {
        id = "box2",
        displayName = "Battle Box",
        boxModelName = "Box2",
        weight = 35,
        heroPool = { "Akaza", "Gyutaro", "Zenitsu" },
    },
    {
        id = "box3",
        displayName = "Demon Case",
        boxModelName = "Box3",
        weight = 25,
        heroPool = { "Kokushibo", "Muzan Kibutsuji", "Akaza" },
    },
}

local byId: { [string]: ContainerTemplate } = {}
for _, t in TEMPLATES do
    byId[t.id] = t
end

-- Hero mesh for MVP: Workspace.Secret (see HeroModel). heroPool kept for future catalog.
local ContainerCatalog = {
    byId = byId,
    OFFER_COUNT = 5,
    HERO_TEMPLATE = "Secret",
}

function ContainerCatalog.all(): { ContainerTemplate }
    return TEMPLATES
end

function ContainerCatalog.get(id: string): ContainerTemplate?
    return byId[id]
end

return ContainerCatalog
