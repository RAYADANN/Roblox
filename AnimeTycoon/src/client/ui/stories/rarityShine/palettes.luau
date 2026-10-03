--!strict
-- Палитры Rare-лейблов из Workspace.Rarity (snapshot для shine lab).

export type Key = { t: number, c: Color3 }

export type RarityPalette = {
    id: string,
    displayName: string,
    keys: { Key },
    baseRotation: number,
    stroke: Color3,
}

local function rgb(r: number, g: number, b: number): Color3
    return Color3.fromRGB(r, g, b)
end

-- Studio folder "Uncomon" → id uncommon / display Uncommon
local Palettes: { RarityPalette } = {
    {
        id = "common",
        displayName = "Common",
        baseRotation = 90,
        stroke = rgb(0, 0, 0),
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
        keys = {
            { t = 0, c = rgb(170, 0, 0) },
            { t = 1, c = rgb(8, 8, 8) },
        },
    },
}

local function toColorSequence(keys: { Key }): ColorSequence
    local points = table.create(#keys)
    for i, key in keys do
        points[i] = ColorSequenceKeypoint.new(key.t, key.c)
    end
    return ColorSequence.new(points)
end

return {
    all = Palettes,
    toColorSequence = toColorSequence,
}
