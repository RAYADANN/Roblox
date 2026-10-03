--!strict
-- Палитры Mutation-лейблов из Workspace.Mutations (snapshot для shine lab).

export type Key = { t: number, c: Color3 }

export type MutationPalette = {
    id: string,
    displayName: string,
    keys: { Key },
    baseRotation: number,
    stroke: Color3,
}

local function rgb(r: number, g: number, b: number): Color3
    return Color3.fromRGB(r, g, b)
end

-- RGB из Studio (0–1 → 0–255), округлено.
local Palettes: { MutationPalette } = {
    {
        id = "normal",
        displayName = "Normal",
        baseRotation = 0,
        stroke = rgb(0, 0, 0),
        -- в Studio без градиента — мягкий белый для видимого shine
        keys = {
            { t = 0, c = rgb(220, 220, 220) },
            { t = 0.5, c = rgb(255, 255, 255) },
            { t = 1, c = rgb(220, 220, 220) },
        },
    },
    {
        id = "secret",
        displayName = "Secret",
        baseRotation = -73,
        stroke = rgb(0, 0, 0),
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
        keys = {
            { t = 0, c = rgb(255, 255, 0) },
            { t = 0.424, c = rgb(251, 251, 0) },
            { t = 1, c = rgb(255, 85, 0) },
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
