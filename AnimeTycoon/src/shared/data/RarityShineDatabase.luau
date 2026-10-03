--!strict
-- Палитры + выбранные shine-варианты для Rare-текста (GameAssets.Rarity).
-- RGB 0–255 — без Color3 (Lune CI).

export type Rgb = { r: number, g: number, b: number }
export type Key = { t: number, c: Rgb }

export type RarityShineDef = {
    id: string,
    displayName: string,
    keys: { Key },
    baseRotation: number,
    stroke: Rgb,
    --- ColorSheen S1–S16; 0 = без анимации
    variant: number,
}

local function rgb(r: number, g: number, b: number): Rgb
    return { r = r, g = g, b = b }
end

local DEFS: { RarityShineDef } = {
    {
        id = "common",
        displayName = "Common",
        baseRotation = 90,
        stroke = rgb(0, 0, 0),
        variant = 0,
        keys = {
            { t = 0, c = rgb(44, 44, 44) },
            { t = 1, c = rgb(255, 255, 255) },
        },
    },
    {
        id = "uncommon",
        displayName = "Uncommon",
        baseRotation = 90,
        stroke = rgb(0, 0, 0),
        variant = 0,
        keys = {
            { t = 0, c = rgb(0, 255, 0) },
            { t = 1, c = rgb(255, 255, 255) },
        },
    },
    {
        id = "rare",
        displayName = "Rare",
        baseRotation = 90,
        stroke = rgb(0, 0, 0),
        variant = 13,
        keys = {
            { t = 0, c = rgb(0, 255, 255) },
            { t = 1, c = rgb(255, 255, 255) },
        },
    },
    {
        id = "legendary",
        displayName = "Legendary",
        baseRotation = 90,
        stroke = rgb(0, 0, 0),
        variant = 1,
        keys = {
            { t = 0, c = rgb(255, 255, 0) },
            { t = 1, c = rgb(255, 85, 0) },
        },
    },
    {
        id = "mythic",
        displayName = "Mythic",
        baseRotation = 90,
        stroke = rgb(0, 0, 0),
        variant = 9,
        keys = {
            { t = 0, c = rgb(170, 0, 0) },
            { t = 1, c = rgb(8, 8, 8) },
        },
    },
    {
        id = "null",
        displayName = "Null",
        baseRotation = 0,
        stroke = rgb(0, 0, 0),
        variant = 15, -- ColorSheen S15 Candy
        keys = {
            { t = 0, c = rgb(170, 85, 255) },
            { t = 0.25, c = rgb(255, 80, 180) },
            { t = 0.5, c = rgb(80, 220, 255) },
            { t = 0.75, c = rgb(255, 230, 60) },
            { t = 1, c = rgb(170, 85, 255) },
        },
    },
}

local byId: { [string]: RarityShineDef } = {}
local byDisplay: { [string]: RarityShineDef } = {}
for _, def in DEFS do
    byId[def.id] = def
    byDisplay[string.lower(def.displayName)] = def
end

local RarityShineDatabase = {}

function RarityShineDatabase.all(): { RarityShineDef }
    return DEFS
end

function RarityShineDatabase.get(id: string): RarityShineDef?
    return byId[string.lower(id)]
end

function RarityShineDatabase.getByDisplayName(name: string): RarityShineDef?
    return byDisplay[string.lower(name)]
end

function RarityShineDatabase.resolve(rarityIdOrLabel: string): RarityShineDef?
    if rarityIdOrLabel == "" then
        return nil
    end
    local lower = string.lower(rarityIdOrLabel)
    return byId[lower] or byDisplay[lower]
end

return RarityShineDatabase
