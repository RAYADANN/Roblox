--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local StrokeText = require(script.Parent.Parent.Parent.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local layout = require(script.Parent.Parent.layout)
local tokens = require(script.Parent.Parent.tokens)

export type Props = {
    title: string,
    onClose: () -> (),
}

local function WindowHeader(props: Props): React.Node
    return React.createElement("Frame", {
        Size = layout.header,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = tokens.zWindow,
    }, {
        Icon = React.createElement("ImageLabel", {
            Size = UDim2.fromOffset(tokens.close, tokens.close),
            Position = UDim2.fromOffset(tokens.pad, (tokens.headerH - tokens.close) / 2),
            BackgroundTransparency = 1,
            Image = assets.icon,
            ScaleType = Enum.ScaleType.Fit,
        }),
        Title = React.createElement(StrokeText, {
            text = props.title,
            size = layout.title,
            position = UDim2.fromOffset(tokens.pad + tokens.close + 8, 0),
            anchorPoint = Vector2.new(0, 0),
            textXAlignment = Enum.TextXAlignment.Left,
            font = tokens.font,
            color = tokens.titleColor,
            strokeThickness = tokens.stroke,
            designSpace = true,
            uniformFitRef = "WINDOW",
            zIndex = tokens.zWindow,
        }),
        Close = React.createElement("TextButton", {
            Size = layout.close,
            Position = UDim2.new(1, -tokens.pad, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = tokens.closeBg,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            [React.Event.Activated] = props.onClose,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
            Label = React.createElement(StrokeText, {
                text = "X",
                size = UDim2.fromScale(1, 1),
                textSize = 18,
                designSpace = true,
                font = tokens.font,
                color = tokens.titleColor,
                strokeThickness = tokens.stroke,
            }),
        }),
    })
end

return WindowHeader
