--!strict
-- CS-style crosshair presets (cosmetic). Shoot wall panel to equip.
--# selene: allow(incorrect_standard_library_use)

export type CrosshairStyle = "dot" | "cross" | "cross_dot" | "t" | "circle" | "gap_cross"

export type CrosshairDef = {
    id: string,
    name: string,
    style: CrosshairStyle,
    --- 0–1 RGB
    r: number,
    g: number,
    b: number,
    size: number,
    gap: number,
    thickness: number,
    outline: boolean,
}

local DEFAULT_ID = "classic"

local ORDERED: { CrosshairDef } = {
    {
        id = "classic",
        name = "Classic",
        style = "cross",
        r = 0,
        g = 1,
        b = 0,
        size = 10,
        gap = 4,
        thickness = 2,
        outline = true,
    },
    {
        id = "dot",
        name = "Dot",
        style = "dot",
        r = 0,
        g = 1,
        b = 0,
        size = 4,
        gap = 0,
        thickness = 4,
        outline = true,
    },
    {
        id = "cross_dot",
        name = "Cross+Dot",
        style = "cross_dot",
        r = 0,
        g = 1,
        b = 0,
        size = 12,
        gap = 3,
        thickness = 2,
        outline = true,
    },
    {
        id = "t_cross",
        name = "T",
        style = "t",
        r = 0,
        g = 1,
        b = 0,
        size = 12,
        gap = 3,
        thickness = 2,
        outline = true,
    },
    {
        id = "gap",
        name = "Gap",
        style = "gap_cross",
        r = 0,
        g = 1,
        b = 0,
        size = 14,
        gap = 8,
        thickness = 2,
        outline = true,
    },
    {
        id = "circle",
        name = "Circle",
        style = "circle",
        r = 0,
        g = 1,
        b = 0,
        size = 14,
        gap = 0,
        thickness = 2,
        outline = false,
    },
    {
        id = "cyan",
        name = "Cyan",
        style = "cross",
        r = 0.2,
        g = 0.95,
        b = 1,
        size = 10,
        gap = 4,
        thickness = 2,
        outline = true,
    },
    {
        id = "yellow_dot",
        name = "Yellow Dot",
        style = "dot",
        r = 1,
        g = 0.92,
        b = 0.2,
        size = 5,
        gap = 0,
        thickness = 5,
        outline = true,
    },
}

local BY_ID: { [string]: CrosshairDef } = {}
for _, def in ORDERED do
    BY_ID[def.id] = def
end

local CrosshairDatabase = {}

function CrosshairDatabase.defaultId(): string
    return DEFAULT_ID
end

function CrosshairDatabase.get(id: string): CrosshairDef?
    return BY_ID[id]
end

function CrosshairDatabase.isValid(id: string): boolean
    return BY_ID[id] ~= nil
end

function CrosshairDatabase.list(): { CrosshairDef }
    return ORDERED
end

function CrosshairDatabase.displayName(id: string): string
    local def = BY_ID[id]
    return if def then def.name else id
end

return CrosshairDatabase
