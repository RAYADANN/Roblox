--!strict
-- Locked mutation row: ColorSheen S# (Prismatic = legacy V3).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local palettes = require(script.Parent.palettes)

export type Props = {
    palette: palettes.MutationPalette,
    variant: number,
    legacyMutationV: number?,
    layoutOrder: number?,
}

local function resolveApply(): any
    local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    local client = sps and sps:FindFirstChild("client")
    local core = client and client:FindFirstChild("core")
    local mod = core and core:FindFirstChild("ColorSheenApply")
    if mod and mod:IsA("ModuleScript") then
        return require(mod)
    end
    error("[mutationShine.ShineCell] ColorSheenApply missing")
end

local ColorSheenApply = resolveApply()

local function toRgbKeys(keys: { palettes.Key }): { any }
    local out = {}
    for _, key in keys do
        table.insert(out, {
            t = key.t,
            c = {
                r = math.floor(key.c.R * 255 + 0.5),
                g = math.floor(key.c.G * 255 + 0.5),
                b = math.floor(key.c.B * 255 + 0.5),
            },
        })
    end
    return out
end

local function ShineCell(props: Props): React.Node
    local palette = props.palette
    local variant = props.variant
    local legacy = props.legacyMutationV
    local gradientRef = React.useRef(nil :: UIGradient?)
    local textRef = React.useRef(nil :: TextLabel?)
    local rgbKeys = toRgbKeys(palette.keys)

    local tag = if typeof(legacy) == "number" and legacy > 0
        then `legacy V{legacy}`
        elseif variant <= 0 then "none"
        else `S{variant}`

    React.useEffect(function()
        local t0 = os.clock()
        local conn = RunService.Heartbeat:Connect(function()
            local grad = gradientRef.current
            local text = textRef.current
            if grad == nil or text == nil then
                return
            end
            local t = os.clock() - t0
            local pose = if typeof(legacy) == "number" and legacy > 0
                then ColorSheenApply.poseLegacyMutation(legacy, t, palette.baseRotation)
                else ColorSheenApply.poseColorSheen(variant, t, palette.baseRotation, rgbKeys)
            ColorSheenApply.applyPose(text, grad, pose, rgbKeys)
        end)
        return function()
            conn:Disconnect()
        end
    end, { palette.id, variant, legacy, palette.baseRotation } :: { unknown })

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(168, 88),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Stroke = React.createElement("UIStroke", {
            Color = Color3.fromRGB(48, 54, 72),
            Thickness = 1,
        }),
        Tag = React.createElement("TextLabel", {
            Size = UDim2.new(1, -12, 0, 18),
            Position = UDim2.fromOffset(6, 6),
            BackgroundTransparency = 1,
            Text = tag,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(160, 168, 190),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
        }),
        Sample = React.createElement("TextLabel", {
            Size = UDim2.new(1, -16, 0, 40),
            Position = UDim2.new(0.5, 0, 0.58, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = palette.displayName,
            Font = Enum.Font.FredokaOne,
            TextSize = 28,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 2,
            ref = function(rbx: TextLabel?)
                textRef.current = rbx
            end,
        }, {
            Outline = React.createElement("UIStroke", {
                Color = Color3.new(0, 0, 0),
                Thickness = 3,
                StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
                LineJoinMode = Enum.LineJoinMode.Round,
            }),
            Gradient = React.createElement("UIGradient", {
                Color = palettes.toColorSequence(palette.keys),
                Rotation = palette.baseRotation,
                ref = function(rbx: UIGradient?)
                    gradientRef.current = rbx
                end,
            }),
        }),
    })
end

return ShineCell
