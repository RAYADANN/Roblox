--!strict
-- Cosmetic USP skins. Ownership = shop; kill-flex is temporary (not here).
-- Tracer RGB is skin-bound (visual only — no aim advantage).

export type Rgb8 = {
    r: number,
    g: number,
    b: number,
}

export type SkinDef = {
    id: string,
    name: string,
    rarity: string,
    tracer: Rgb8,
}

local DEFAULT_TRACER: Rgb8 = { r = 255, g = 236, b = 170 }

local SKINS: { [string]: SkinDef } = {
    usp_default = {
        id = "usp_default",
        name = "USP",
        rarity = "common",
        tracer = DEFAULT_TRACER,
    },
    usp_slate = {
        id = "usp_slate",
        name = "Slate",
        rarity = "uncommon",
        tracer = { r = 160, g = 190, b = 220 },
    },
    usp_crimson = {
        id = "usp_crimson",
        name = "Crimson",
        rarity = "rare",
        tracer = { r = 255, g = 70, b = 80 },
    },
    usp_neon = {
        id = "usp_neon",
        name = "Neon",
        rarity = "epic",
        tracer = { r = 80, g = 255, b = 220 },
    },
    usp_ember = {
        id = "usp_ember",
        name = "Ember",
        rarity = "legendary",
        tracer = { r = 255, g = 140, b = 40 },
    },
    usp_void = {
        id = "usp_void",
        name = "Void",
        rarity = "mythic",
        tracer = { r = 180, g = 80, b = 255 },
    },
    usp_frost = {
        id = "usp_frost",
        name = "Frost",
        rarity = "rare",
        tracer = { r = 140, g = 220, b = 255 },
    },
    usp_jade = {
        id = "usp_jade",
        name = "Jade",
        rarity = "uncommon",
        tracer = { r = 80, g = 220, b = 140 },
    },
    usp_solar = {
        id = "usp_solar",
        name = "Solar",
        rarity = "epic",
        tracer = { r = 255, g = 200, b = 60 },
    },
    usp_obsidian = {
        id = "usp_obsidian",
        name = "Obsidian",
        rarity = "legendary",
        tracer = { r = 90, g = 90, b = 110 },
    },
    usp_azure = {
        id = "usp_azure",
        name = "Azure",
        rarity = "rare",
        tracer = { r = 60, g = 140, b = 255 },
    },
    usp_rose = {
        id = "usp_rose",
        name = "Rose",
        rarity = "common",
        tracer = { r = 255, g = 150, b = 180 },
    },
    usp_copper = {
        id = "usp_copper",
        name = "Copper",
        rarity = "uncommon",
        tracer = { r = 220, g = 120, b = 60 },
    },
    usp_cobalt = {
        id = "usp_cobalt",
        name = "Cobalt",
        rarity = "rare",
        tracer = { r = 40, g = 90, b = 220 },
    },
    usp_toxin = {
        id = "usp_toxin",
        name = "Toxin",
        rarity = "epic",
        tracer = { r = 140, g = 255, b = 40 },
    },
    usp_plasma = {
        id = "usp_plasma",
        name = "Plasma",
        rarity = "legendary",
        tracer = { r = 220, g = 80, b = 255 },
    },
    usp_ivory = {
        id = "usp_ivory",
        name = "Ivory",
        rarity = "common",
        tracer = { r = 245, g = 240, b = 220 },
    },
    usp_graphite = {
        id = "usp_graphite",
        name = "Graphite",
        rarity = "uncommon",
        tracer = { r = 120, g = 120, b = 130 },
    },
    usp_amber = {
        id = "usp_amber",
        name = "Amber",
        rarity = "rare",
        tracer = { r = 255, g = 170, b = 40 },
    },
    usp_nova = {
        id = "usp_nova",
        name = "Nova",
        rarity = "mythic",
        tracer = { r = 255, g = 255, b = 120 },
    },
}

local SkinDatabase = {}

function SkinDatabase.get(id: string): SkinDef?
    return SKINS[id]
end

function SkinDatabase.isValid(id: string): boolean
    return SKINS[id] ~= nil
end

function SkinDatabase.displayName(id: string): string
    local def = SKINS[id]
    return if def then def.name else id
end

function SkinDatabase.resolveId(id: string): string
    if SKINS[id] then
        return id
    end
    return "usp_default"
end

--- Stable id list for inventory / shop grids.
function SkinDatabase.listIds(): { string }
    return {
        "usp_default",
        "usp_slate",
        "usp_crimson",
        "usp_neon",
        "usp_ember",
        "usp_void",
        "usp_frost",
        "usp_jade",
        "usp_solar",
        "usp_obsidian",
        "usp_azure",
        "usp_rose",
        "usp_copper",
        "usp_cobalt",
        "usp_toxin",
        "usp_plasma",
        "usp_ivory",
        "usp_graphite",
        "usp_amber",
        "usp_nova",
    }
end

--- Tracer color channels 0–255 for the visible skin (flex or equipped).
function SkinDatabase.tracerRgb(id: string): Rgb8
    local def = SKINS[SkinDatabase.resolveId(id)]
    if def then
        return def.tracer
    end
    return DEFAULT_TRACER
end

return SkinDatabase
