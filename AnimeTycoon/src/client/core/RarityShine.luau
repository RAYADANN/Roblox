--!strict
-- Bind Rarity shine (ColorSheen S#) onto Rare TextLabel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ColorSheenApply = require(script.Parent.ColorSheenApply)
local RarityShineDatabase = require(ReplicatedStorage.shared.data.RarityShineDatabase)

type Binding = {
    conn: RBXScriptConnection,
    gradient: UIGradient,
    key: string,
    t0: number,
}

local bindings: { [TextLabel]: Binding } = {}

local RarityShine = {}

local function toColor3(c: RarityShineDatabase.Rgb): Color3
    return Color3.fromRGB(c.r, c.g, c.b)
end

local function ensureGradient(
    label: TextLabel,
    def: RarityShineDatabase.RarityShineDef,
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

local function ensureStroke(label: TextLabel, def: RarityShineDatabase.RarityShineDef)
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if stroke == nil then
        stroke = Instance.new("UIStroke")
        stroke.Parent = label
    end
    stroke.Color = toColor3(def.stroke)
    stroke.LineJoinMode = Enum.LineJoinMode.Bevel
end

function RarityShine.unbind(label: TextLabel)
    local binding = bindings[label]
    if binding == nil then
        return
    end
    binding.conn:Disconnect()
    bindings[label] = nil
end

function RarityShine.apply(label: TextLabel, rarityIdOrLabel: string)
    local def = RarityShineDatabase.resolve(rarityIdOrLabel)
    if def == nil then
        RarityShine.unbind(label)
        return
    end

    local existing = bindings[label]
    if existing and existing.key == def.id and existing.conn.Connected then
        return
    end

    RarityShine.unbind(label)

    ensureStroke(label, def)
    local grad = ensureGradient(label, def, true)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)

    if def.variant <= 0 then
        ColorSheenApply.applyPose(
            label,
            grad,
            ColorSheenApply.poseColorSheen(0, 0, def.baseRotation, def.keys),
            def.keys
        )
        return
    end

    local t0 = os.clock()
    local conn = RunService.Heartbeat:Connect(function()
        if label.Parent == nil or grad.Parent == nil then
            RarityShine.unbind(label)
            return
        end
        local pose =
            ColorSheenApply.poseColorSheen(def.variant, os.clock() - t0, def.baseRotation, def.keys)
        ColorSheenApply.applyPose(label, grad, pose, def.keys)
    end)
    bindings[label] = { conn = conn, gradient = grad, key = def.id, t0 = t0 }
end

return RarityShine
