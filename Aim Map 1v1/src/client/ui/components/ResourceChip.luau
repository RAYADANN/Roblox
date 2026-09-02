--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Formatters = require(script.Parent.Parent.util.Formatters)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

export type Props = {
    amount: number,
    layoutOrder: number?,
}

local function ResourceChip(props: Props): React.Node
    local display = useFlipperSpring(props.amount, MotionPresets.SPRING_NUMBER)

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(252, 60),
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
            Size = UDim2.new(0, 4, 1, -15),
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = theme.Colors.gold,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        }),
        Amount = React.createElement("TextLabel", {
            Size = UDim2.new(1, -72, 1, 0),
            Position = UDim2.new(0, 72, 0, 0),
            BackgroundTransparency = 1,
            Text = Formatters.shortNumber(math.floor(display + 0.5)),
            TextSize = 24,
            Font = theme.Font.title,
            TextColor3 = theme.Colors.gold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })
end

return ResourceChip
