--!strict
-- Палитры + выбранные shine-варианты для Mutation-текста (GameAssets.Mutations).
-- RGB 0–255 — без Color3 (Lune CI).

export type Rgb = { r: number, g: number, b: number }
export type Key = { t: number, c: Rgb }

export type MutationShineDef = {
    id: string,
    displayName: string,
    keys: { Key },
    baseRotation: number,
    stroke: Rgb,
    --- ColorSheen S1–S16; 0 = static. Ignored when legacyMutationV set.
    variant: number,
    --- Old MutationShineLogic V1–V5 (Prismatic keeps prior look).
    legacyMutationV: number?,
}

local function rgb(r: number, g: number, b: number): Rgb
    return { r = r, g = g, b = b }
end

local DEFS: { MutationShineDef } = {
    {
        id = "normal",
        displayName = "Normal",
        baseRotation = 0,
        stroke = rgb(0, 0, 0),
        variant = 0,
        keys = {
            { t = 0, c = rgb(255, 255, 255) },
            { t = 1, c = rgb(255, 255, 255) },
        },
    },
    {
        id = "secret",
        displayName = "Secret",
        baseRotation = -73,
        stroke = rgb(0, 0, 0),
        variant = 5,
        keys = {
            { t = 0, c = rgb(0, 0, 0) },
            { t = 0.509, c = rgb(250, 255, 254) },
            { t = 1, c = rgb(0, 0, 0) },
        },
    },
    {
        id = "galaxy",
        displayName = "Galaxy",
        baseRotation = -73,
        stroke = rgb(0, 0, 0),
        variant = 2,
        keys = {
            { t = 0, c = rgb(170, 85, 255) },
            { t = 0.509, c = rgb(250, 255, 254) },
            { t = 1, c = rgb(170, 85, 255) },
        },
    },
    {
        id = "diamond",
        displayName = "Diamond",
        baseRotation = 24,
        stroke = rgb(0, 0, 0),
        variant = 4,
        keys = {
            { t = 0, c = rgb(85, 170, 255) },
            { t = 0.509, c = rgb(250, 255, 254) },
            { t = 1, c = rgb(85, 170, 255) },
        },
    },
    {
        id = "prismatic",
        displayName = "Prismatic",
        baseRotation = 24,
        stroke = rgb(0, 0, 0),
        variant = 0,
        legacyMutationV = 3,
        keys = {
            { t = 0, c = rgb(170, 85, 255) },
            { t = 0.275, c = rgb(170, 85, 255) },
            { t = 0.396, c = rgb(245, 10, 44) },
            { t = 0.517, c = rgb(255, 0, 17) },
            { t = 0.723, c = rgb(255, 232, 10) },
            { t = 1, c = rgb(255, 239, 10) },
        },
    },
    {
        id = "golden",
        displayName = "Golden",
        baseRotation = 90,
        stroke = rgb(0, 0, 0),
        variant = 5,
        keys = {
            { t = 0, c = rgb(255, 255, 0) },
            { t = 0.424, c = rgb(251, 251, 0) },
            { t = 1, c = rgb(255, 85, 0) },
        },
    },
}

local byId: { [string]: MutationShineDef } = {}
local byDisplay: { [string]: MutationShineDef } = {}
for _, def in DEFS do
    byId[def.id] = def
    byDisplay[string.lower(def.displayName)] = def
end

local MutationShineDatabase = {}

function MutationShineDatabase.all(): { MutationShineDef }
    return DEFS
end

function MutationShineDatabase.get(id: string): MutationShineDef?
    return byId[string.lower(id)]
end

function MutationShineDatabase.getByDisplayName(name: string): MutationShineDef?
    return byDisplay[string.lower(name)]
end

function MutationShineDatabase.resolveFromLabel(label: string): MutationShineDef?
    if label == "" then
        return nil
    end
    local first = string.match(label, "^([^-]+)") or label
    local byName = MutationShineDatabase.getByDisplayName(first)
    if byName then
        return byName
    end
    return MutationShineDatabase.get(first)
end

return MutationShineDatabase
