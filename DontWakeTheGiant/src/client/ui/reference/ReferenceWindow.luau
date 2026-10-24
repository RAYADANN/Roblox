--!strict
-- Window chrome. One UIScale, every widget is a design-pixel offset.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local StrokeText = require(script.Parent.Parent.components.StrokeText)
local WindowHeader = require(script.Parent.components.WindowHeader)
local layout = require(script.Parent.layout)
local theme = require(script.Parent.Parent.theme)
local tokens = require(script.Parent.tokens)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    title: string,
    body: string,
    onClose: () -> (),
}

local function ReferenceWindow(props: Props): React.Node
    local metrics = useLayout()
    local fit = metrics.modalFitScale(tokens.windowW, tokens.windowH)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.bg1,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = tokens.zWindow,
    }, {
        Window = React.createElement("Frame", {
            Size = layout.window,
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = tokens.bg,
            BorderSizePixel = 0,
            ZIndex = tokens.zWindow,
        }, {
            Scale = React.createElement("UIScale", { Scale = fit }),
            Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
            Stroke = React.createElement("UIStroke", {
                Color = tokens.strokeColor,
                Thickness = tokens.stroke,
                StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
            }),
            Header = React.createElement(WindowHeader, {
                title = props.title,
                onClose = props.onClose,
            }),
            Body = React.createElement(StrokeText, {
                text = props.body,
                size = layout.body,
                position = UDim2.fromOffset(tokens.pad, tokens.headerH + tokens.pad),
                anchorPoint = Vector2.new(0, 0),
                textXAlignment = Enum.TextXAlignment.Left,
                textYAlignment = Enum.TextYAlignment.Top,
                textSize = tokens.body,
                font = tokens.bodyFont,
                color = tokens.bodyColor,
                strokeThickness = tokens.stroke,
                designSpace = true,
                zIndex = tokens.zWindow,
            }),
        }),
    })
end

return ReferenceWindow
