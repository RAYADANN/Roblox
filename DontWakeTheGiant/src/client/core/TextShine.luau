--!strict
-- Drive a text gradient from ColorSheenLogic or RarityShineLogic. One binder, no rarity table.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ColorSheenApply = require(script.Parent.ColorSheenApply)
local ColorSheenLogic = require(ReplicatedStorage.shared.util.ColorSheenLogic)
local RarityShineLogic = require(ReplicatedStorage.shared.util.RarityShineLogic)

export type Style = {
    --- "sheen" uses ColorSheenLogic (1..16). "rarity" uses RarityShineLogic (1..8).
    kind: "sheen" | "rarity",
    variant: number,
    baseRotation: number,
    keys: { ColorSheenLogic.Key },
}

local TextShine = {}

local function ensureGradient(label: TextLabel, keys: { ColorSheenLogic.Key }): UIGradient
    local grad = label:FindFirstChildOfClass("UIGradient")
    if grad == nil then
        local created = Instance.new("UIGradient")
        created.Parent = label
        grad = created
    end
    grad.Color = ColorSheenApply.sequenceFromKeys(keys)
    grad.Enabled = true
    return grad
end

local function poseAt(style: Style, t: number): ColorSheenLogic.SheenPose
    if style.kind == "rarity" then
        local pose = RarityShineLogic.pose(style.variant, t, style.baseRotation)
        return {
            offset = pose.offset,
            rotation = pose.rotation,
            midTransparency = pose.midTransparency,
        }
    end
    return ColorSheenLogic.pose(style.variant, t, style.baseRotation, style.keys)
end

function TextShine.bind(label: TextLabel, style: Style): () -> ()
    local grad = ensureGradient(label, style.keys)
    local t0 = os.clock()
    local conn = RunService.Heartbeat:Connect(function()
        if label.Parent == nil or grad.Parent == nil then
            return
        end
        ColorSheenApply.applyPose(label, grad, poseAt(style, os.clock() - t0), style.keys)
    end)
    return function()
        conn:Disconnect()
    end
end

return TextShine
