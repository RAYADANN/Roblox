--!strict
-- ColorSequence для Index StrokeText из MutationShine / RarityShine databases.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationShineDatabase =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("data").MutationShineDatabase)
local RarityShineDatabase =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("data").RarityShineDatabase)

local ShineGradients = {}

local function toColor3(c: { r: number, g: number, b: number }): Color3
    return Color3.fromRGB(c.r, c.g, c.b)
end

local function toSequence(
    keys: { { t: number, c: { r: number, g: number, b: number } } }
): ColorSequence
    local points = table.create(#keys)
    for i, key in keys do
        points[i] = ColorSequenceKeypoint.new(key.t, toColor3(key.c))
    end
    return ColorSequence.new(points)
end

export type GradientProp = {
    color: ColorSequence,
    rotation: number,
}

function ShineGradients.forMutation(labelOrId: string): GradientProp?
    local def = MutationShineDatabase.resolveFromLabel(labelOrId)
        or MutationShineDatabase.get(labelOrId)
    if def == nil then
        return nil
    end
    return {
        color = toSequence(def.keys),
        rotation = def.baseRotation,
    }
end

function ShineGradients.forRarity(labelOrId: string): GradientProp?
    local def = RarityShineDatabase.resolve(labelOrId)
    if def == nil then
        return nil
    end
    return {
        color = toSequence(def.keys),
        rotation = def.baseRotation,
    }
end

return ShineGradients
