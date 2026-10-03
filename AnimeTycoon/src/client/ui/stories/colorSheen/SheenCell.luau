--!strict
-- Ячейка: палитра + ColorSheen S1–S16 (sheen + recolor).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ColorSheenLogic =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("util").ColorSheenLogic)

export type Key = { t: number, c: Color3 }

export type Props = {
    sampleText: string,
    keys: { Key },
    baseRotation: number,
    stroke: Color3,
    variant: number,
    layoutOrder: number?,
}

local function toRgbKeys(keys: { Key }): { ColorSheenLogic.Key }
    local out: { ColorSheenLogic.Key } = {}
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

local function sequenceFromRgb(keys: { ColorSheenLogic.Key }): ColorSequence
    local points = table.create(#keys)
    for i, key in keys do
        points[i] = ColorSequenceKeypoint.new(key.t, Color3.fromRGB(key.c.r, key.c.g, key.c.b))
    end
    return ColorSequence.new(points)
end

local function sequenceFromColor3(keys: { Key }): ColorSequence
    local points = table.create(#keys)
    for i, key in keys do
        points[i] = ColorSequenceKeypoint.new(key.t, key.c)
    end
    return ColorSequence.new(points)
end

local function applyMid(grad: UIGradient, mid: number?)
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

local function SheenCell(props: Props): React.Node
    local variant = props.variant
    local labels = ColorSheenLogic.labels()
    local tag = labels[variant] or ("S" .. tostring(variant))
    local gradientRef = React.useRef(nil :: UIGradient?)
    local textRef = React.useRef(nil :: TextLabel?)
    local rgbKeys = toRgbKeys(props.keys)

    React.useEffect(function()
        local t0 = os.clock()
        local conn = RunService.Heartbeat:Connect(function()
            local text = textRef.current
            local grad = gradientRef.current
            if text == nil or text.Parent == nil then
                return
            end
            local pose = ColorSheenLogic.pose(variant, os.clock() - t0, props.baseRotation, rgbKeys)

            if pose.solid then
                if grad then
                    grad.Enabled = false
                end
                text.TextColor3 = Color3.fromRGB(pose.solid.r, pose.solid.g, pose.solid.b)
            else
                text.TextColor3 = Color3.fromRGB(255, 255, 255)
                if grad then
                    grad.Enabled = true
                    if pose.keys then
                        grad.Color = sequenceFromRgb(pose.keys)
                    else
                        grad.Color = sequenceFromColor3(props.keys)
                    end
                    grad.Offset = Vector2.new(pose.offset.x, pose.offset.y)
                    grad.Rotation = pose.rotation
                    applyMid(grad, pose.midTransparency)
                end
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, { variant, props.baseRotation, props.sampleText } :: { unknown })

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(148, 84),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Border = React.createElement("UIStroke", {
            Color = Color3.fromRGB(48, 58, 76),
            Thickness = 1,
        }),
        Tag = React.createElement("TextLabel", {
            Size = UDim2.new(1, -10, 0, 15),
            Position = UDim2.fromOffset(5, 4),
            BackgroundTransparency = 1,
            Text = tag,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(160, 168, 190),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
        }),
        Sample = React.createElement("TextLabel", {
            Size = UDim2.new(1, -10, 0, 42),
            Position = UDim2.new(0.5, 0, 0.58, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = props.sampleText,
            Font = Enum.Font.FredokaOne,
            TextSize = 24,
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
                Color = sequenceFromColor3(props.keys),
                Rotation = props.baseRotation,
                ref = function(rbx: UIGradient?)
                    gradientRef.current = rbx
                end,
            }),
        }),
    })
end

return SheenCell
