--!strict
-- Ячейка lab: один Roblox-native text FX вариант.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local TextFxLogic = require(script.Parent.TextFxLogic)

export type Props = {
    variant: number,
    sampleText: string?,
    layoutOrder: number?,
}

local GOLD_A = Color3.fromRGB(255, 220, 80)
local GOLD_B = Color3.fromRGB(255, 140, 40)
local STROKE = Color3.fromRGB(40, 28, 8)

local function fullGradient(): ColorSequence
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 160)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 190, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 30)),
    })
end

--- Узкая яркая полоса — типичный Roblox sheen на тексте.
local function stripeGradient(): ColorSequence
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 110, 30)),
        ColorSequenceKeypoint.new(0.38, Color3.fromRGB(200, 130, 40)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 230)),
        ColorSequenceKeypoint.new(0.58, Color3.fromRGB(200, 130, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 90, 25)),
    })
end

local function FxCell(props: Props): React.Node
    local variant = props.variant
    local labels = TextFxLogic.labels()
    local label = labels[variant] or ("V" .. tostring(variant))
    local sample = props.sampleText or "Golden"

    local gradientRef = React.useRef(nil :: UIGradient?)
    local strokeRef = React.useRef(nil :: UIStroke?)
    local scaleRef = React.useRef(nil :: UIScale?)
    local textRef = React.useRef(nil :: TextLabel?)

    local usesGradient = variant == 1 or variant == 2 or variant == 9
    local usesSolid = variant == 7
        or variant == 10
        or variant == 5
        or variant == 3
        or variant == 4
        or variant == 6
        or variant == 8

    React.useEffect(function()
        local t0 = os.clock()
        local conn = RunService.Heartbeat:Connect(function()
            local t = os.clock() - t0
            local pose = TextFxLogic.pose(variant, t)

            local grad = gradientRef.current
            if grad and grad.Parent then
                if pose.offsetX ~= nil then
                    grad.Offset = Vector2.new(pose.offsetX, pose.offsetY or 0)
                end
                if pose.rotation ~= nil then
                    grad.Rotation = pose.rotation
                end
            end

            local scale = scaleRef.current
            if scale and scale.Parent and pose.scale ~= nil then
                scale.Scale = pose.scale
            end

            local stroke = strokeRef.current
            if stroke and stroke.Parent and pose.strokeThickness ~= nil then
                stroke.Thickness = pose.strokeThickness
            end

            local text = textRef.current
            if text and text.Parent then
                if pose.transparency ~= nil then
                    text.TextTransparency = pose.transparency
                end
                if pose.bobY ~= nil then
                    text.Position = UDim2.new(0.5, 0, 0.58 + pose.bobY, 0)
                end
                if pose.hue ~= nil then
                    text.TextColor3 = Color3.fromHSV(pose.hue, 0.85, 1)
                end
                if pose.flash ~= nil then
                    text.TextColor3 = if pose.flash < 0.5 then GOLD_A else GOLD_B
                end
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, { variant } :: { unknown })

    local gradientNode: React.Node? = nil
    if usesGradient then
        gradientNode = React.createElement("UIGradient", {
            Color = if variant == 2 then stripeGradient() else fullGradient(),
            Rotation = 0,
            ref = function(rbx: UIGradient?)
                gradientRef.current = rbx
            end,
        })
    end

    local textColor = if usesSolid
            and variant ~= 7
            and variant ~= 10
        then GOLD_A
        elseif variant == 10 then GOLD_A
        else Color3.fromRGB(255, 255, 255)

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(176, 96),
        BackgroundColor3 = Color3.fromRGB(22, 24, 32),
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Border = React.createElement("UIStroke", {
            Color = Color3.fromRGB(52, 58, 76),
            Thickness = 1,
        }),
        Tag = React.createElement("TextLabel", {
            Size = UDim2.new(1, -12, 0, 18),
            Position = UDim2.fromOffset(6, 6),
            BackgroundTransparency = 1,
            Text = label,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(160, 168, 190),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
        }),
        Sample = React.createElement("TextLabel", {
            Size = UDim2.new(1, -16, 0, 44),
            Position = UDim2.new(0.5, 0, 0.58, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = sample,
            Font = Enum.Font.FredokaOne,
            TextSize = 30,
            TextColor3 = textColor,
            ZIndex = 2,
            ref = function(rbx: TextLabel?)
                textRef.current = rbx
            end,
        }, {
            Outline = React.createElement("UIStroke", {
                Color = STROKE,
                Thickness = 2.5,
                StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
                LineJoinMode = Enum.LineJoinMode.Round,
                ref = function(rbx: UIStroke?)
                    strokeRef.current = rbx
                end,
            }),
            Scale = React.createElement("UIScale", {
                Scale = 1,
                ref = function(rbx: UIScale?)
                    scaleRef.current = rbx
                end,
            }),
            Gradient = gradientNode,
        }),
    })
end

return FxCell
