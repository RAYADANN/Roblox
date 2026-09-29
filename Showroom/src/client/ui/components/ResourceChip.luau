--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Formatters = require(script.Parent.Parent.util.Formatters)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    amount: number,
    layoutOrder: number?,
}

local function ResourceChip(props: Props): React.Node
    local layout = useLayout()
    local display = useFlipperSpring(props.amount, MotionPresets.SPRING_NUMBER)

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(layout.px(168), layout.px(40)),
        BackgroundColor3 = theme.Colors.bgChip,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.dockBorder,
            Thickness = theme.Stroke.medium,
        }),
        Bar = React.createElement("Frame", {
            Size = UDim2.new(0, layout.px(3), 1, -layout.gap(10)),
            Position = UDim2.new(0, layout.gap(8), 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = theme.Colors.gold,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        }),
        Amount = React.createElement("TextLabel", {
            Size = UDim2.new(1, -layout.px(48), 1, 0),
            Position = UDim2.new(0, layout.px(48), 0, 0),
            BackgroundTransparency = 1,
            Text = Formatters.shortNumber(math.floor(display + 0.5)),
            TextSize = layout.text(16),
            Font = theme.Font.display,
            TextColor3 = theme.Colors.white,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = true,
        }, {
            SizeConstraint = React.createElement("UITextSizeConstraint", {
                MinTextSize = 10,
                MaxTextSize = layout.text(22),
            }),
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.outlineDark,
                Thickness = theme.Stroke.moneyButtonText,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                LineJoinMode = Enum.LineJoinMode.Round,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
            Grad = (function()
                local def = theme.Gradients.moneyButtonText
                local keys = table.create(#def.keypoints)
                for i, stop in def.keypoints do
                    keys[i] = ColorSequenceKeypoint.new(stop.t, stop.c)
                end
                return React.createElement("UIGradient", {
                    Color = ColorSequence.new(keys),
                    Rotation = def.rotation,
                })
            end)(),
        }),
    })
end

return ResourceChip
