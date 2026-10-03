--!strict
-- Bind Mutation shine (ColorSheen S# or legacy Mutation V#) onto TextLabel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ColorSheenApply = require(script.Parent.ColorSheenApply)
local MutationShineDatabase = require(ReplicatedStorage.shared.data.MutationShineDatabase)

type Binding = {
    conn: RBXScriptConnection,
    gradient: UIGradient,
    key: string,
    t0: number,
}

local bindings: { [TextLabel]: Binding } = {}

local MutationShine = {}

local function toColor3(c: MutationShineDatabase.Rgb): Color3
    return Color3.fromRGB(c.r, c.g, c.b)
end

local function ensureGradient(
    label: TextLabel,
    def: MutationShineDatabase.MutationShineDef,
    resetPose: boolean
): UIGradient
    local grad = label:FindFirstChildOfClass("UIGradient")
    if grad == nil then
        grad = Instance.new("UIGradient")
        grad.Parent = label
        resetPose = true
    end
    grad.Enabled = true
    grad.Color = ColorSheenApply.sequenceFromKeys(def.keys)
    if resetPose then
        grad.Rotation = def.baseRotation
        grad.Offset = Vector2.zero
        ColorSheenApply.applyMid(grad, nil)
    end
    return grad
end

local function ensureStroke(label: TextLabel, def: MutationShineDatabase.MutationShineDef)
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if stroke == nil then
        stroke = Instance.new("UIStroke")
        stroke.Parent = label
    end
    stroke.Color = toColor3(def.stroke)
    stroke.LineJoinMode = Enum.LineJoinMode.Bevel
end

local function computePose(def: MutationShineDatabase.MutationShineDef, t: number)
    local legacy = def.legacyMutationV
    if typeof(legacy) == "number" and legacy > 0 then
        return ColorSheenApply.poseLegacyMutation(legacy, t, def.baseRotation)
    end
    return ColorSheenApply.poseColorSheen(def.variant, t, def.baseRotation, def.keys)
end

function MutationShine.unbind(label: TextLabel)
    local binding = bindings[label]
    if binding == nil then
        return
    end
    binding.conn:Disconnect()
    bindings[label] = nil
end

function MutationShine.apply(label: TextLabel, mutationLabel: string)
    local def = MutationShineDatabase.resolveFromLabel(mutationLabel)
    if def == nil then
        MutationShine.unbind(label)
        return
    end

    local existing = bindings[label]
    if existing and existing.key == def.id and existing.conn.Connected then
        return
    end

    MutationShine.unbind(label)

    ensureStroke(label, def)
    local grad = ensureGradient(label, def, true)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)

    local legacy = def.legacyMutationV
    local animated = (typeof(legacy) == "number" and legacy > 0) or def.variant > 0
    if not animated then
        ColorSheenApply.applyPose(label, grad, computePose(def, 0), def.keys)
        return
    end

    local t0 = os.clock()
    local conn = RunService.Heartbeat:Connect(function()
        if label.Parent == nil or grad.Parent == nil then
            MutationShine.unbind(label)
            return
        end
        ColorSheenApply.applyPose(label, grad, computePose(def, os.clock() - t0), def.keys)
    end)
    bindings[label] = { conn = conn, gradient = grad, key = def.id, t0 = t0 }
end

return MutationShine
