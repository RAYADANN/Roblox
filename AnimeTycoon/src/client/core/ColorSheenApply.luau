--!strict
-- Apply ColorSheenLogic (or legacy MutationShine V) pose onto TextLabel + UIGradient.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ColorSheenLogic = require(ReplicatedStorage.shared.util.ColorSheenLogic)
local MutationShineLogic = require(ReplicatedStorage.shared.util.MutationShineLogic)

export type RgbKey = ColorSheenLogic.Key

local ColorSheenApply = {}

local function toColor3(c: ColorSheenLogic.Rgb): Color3
    return Color3.fromRGB(c.r, c.g, c.b)
end

local function sequenceFromKeys(keys: { ColorSheenLogic.Key }): ColorSequence
    local points = table.create(#keys)
    for i, key in keys do
        points[i] = ColorSequenceKeypoint.new(key.t, toColor3(key.c))
    end
    return ColorSequence.new(points)
end

function ColorSheenApply.applyMid(grad: UIGradient, mid: number?)
    if mid == nil then
        grad.Transparency = NumberSequence.new(0)
        return
    end
    local m = math.clamp(mid, 0, 1)
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, m),
        NumberSequenceKeypoint.new(1, 0),
    })
end

function ColorSheenApply.applyPose(
    label: TextLabel,
    grad: UIGradient,
    pose: ColorSheenLogic.SheenPose,
    baseKeys: { ColorSheenLogic.Key }
)
    if pose.solid then
        grad.Enabled = false
        label.TextColor3 = toColor3(pose.solid)
        return
    end

    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    grad.Enabled = true
    if pose.keys then
        grad.Color = sequenceFromKeys(pose.keys)
    else
        grad.Color = sequenceFromKeys(baseKeys)
    end
    grad.Offset = Vector2.new(pose.offset.x, pose.offset.y)
    grad.Rotation = pose.rotation
    ColorSheenApply.applyMid(grad, pose.midTransparency)
end

function ColorSheenApply.poseColorSheen(
    variant: number,
    t: number,
    baseRotation: number,
    baseKeys: { ColorSheenLogic.Key }
): ColorSheenLogic.SheenPose
    return ColorSheenLogic.pose(variant, t, baseRotation, baseKeys)
end

function ColorSheenApply.poseLegacyMutation(
    variant: number,
    t: number,
    baseRotation: number
): ColorSheenLogic.SheenPose
    local p = MutationShineLogic.pose(variant, t, baseRotation)
    return {
        offset = p.offset,
        rotation = p.rotation,
    }
end

function ColorSheenApply.sequenceFromKeys(keys: { ColorSheenLogic.Key }): ColorSequence
    return sequenceFromKeys(keys)
end

return ColorSheenApply
