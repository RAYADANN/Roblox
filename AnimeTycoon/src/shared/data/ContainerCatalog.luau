--!strict
-- Container (box) + hero template catalog. Meshes live in Workspace.
-- Runtime box mesh = BoxVisualLogic (luck tier + palette), NOT this catalog's boxModelName.
-- Runtime hero = HeroCatalog by rarity. heroPool kept as legacy reference only.

export type ContainerTemplate = {
    id: string,
    displayName: string,
    boxModelName: string, -- legacy fallback (Workspace.Box1 / Box2 / Box3)
    weight: number,
    heroPool: { string }, -- legacy; prefer HeroCatalog
}

local TEMPLATES: { ContainerTemplate } = {
    {
        id = "box1",
        displayName = "Scatolino Tralala",
        boxModelName = "Box1",
        weight = 40,
        heroPool = { "Tanjiro", "Nezuko", "Zenitsu", "Inosuke" },
    },
    {
        id = "box2",
        displayName = "Cassa Bombardini",
        boxModelName = "Box2",
        weight = 35,
        heroPool = { "Akaza", "Gyutaro", "Zenitsu" },
    },
    {
        id = "box3",
        displayName = "Forziere Saturnita",
        boxModelName = "Box3",
        weight = 25,
        heroPool = { "Kokushibo", "Muzan Kibutsuji", "Akaza" },
    },
}

local byId: { [string]: ContainerTemplate } = {}
for _, t in TEMPLATES do
    byId[t.id] = t
end

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
