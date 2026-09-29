--!strict
-- Egg categories for Index (sidebar tabs).

export type EggDef = {
    id: string,
    name: string,
    iconKey: string,
    cardBgKey: string,
}

local ORDER: { EggDef } = {
    {
        id = "domestic",
        name = "Domestic",
        iconKey = "EggDomestic",
        cardBgKey = "CardStandart",
    },
    {
        id = "forest",
        name = "Forest",
        iconKey = "EggForest",
        cardBgKey = "CardGreen",
    },
    {
        id = "ice",
        name = "Ice",
        iconKey = "EggIce",
        cardBgKey = "CardIce",
    },
    {
        id = "volcano",
        name = "Volcano",
        iconKey = "EggVolcano",
        cardBgKey = "CardFire",
    },
}

local byId: { [string]: EggDef } = {}
for _, egg in ORDER do
    byId[egg.id] = egg
end

local EggDatabase = {
    ORDER = ORDER,
    byId = byId,
}

function EggDatabase.get(id: string): EggDef?
    return byId[id]
end

function EggDatabase.defaultId(): string
    return ORDER[1].id
end

return EggDatabase
