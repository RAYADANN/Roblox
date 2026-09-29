--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    price: number,
    onActivated: () -> (),
}

local function SkipAllButton(props: Props): React.Node
    local scale, handlers = useHoverPress({})
    local S = SG.skip

    return React.createElement("ImageButton", {
        Size = S.size,
        Position = S.pos,
        AnchorPoint = S.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = assets.skipBtn,
        ScaleType = Enum.ScaleType.Stretch,
        AutoButtonColor = false,
        ZIndex = 3,
        [React.Event.Activated] = props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Stroke = React.createElement("UIStroke", {
            Color = tokens.titleShadow,
            Thickness = tokens.strokeBtn,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
        Label = React.createElement(StrokeText, {
            text = "Skip All",
            strokeThickness = tokens.strokeText,
            size = S.labelSize,
            position = S.labelPos,
            anchorPoint = Vector2.new(0.5, 0.5),
            zIndex = 2,
        }),
        Price = React.createElement("Frame", {
            Size = S.priceSize,
            Position = S.pricePos,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            Icon = React.createElement("ImageLabel", {
                Size = S.robuxSize,
                Position = S.robuxPos,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = assets.robux,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2,
            }),
            Amount = React.createElement(StrokeText, {
                text = tostring(props.price),
                strokeThickness = tokens.strokeText,
                size = S.amountSize,
                position = S.amountPos,
                anchorPoint = Vector2.new(0.5, 0.5),
                textWrapped = false,
                textXAlignment = Enum.TextXAlignment.Left,
                zIndex = 2,
            }),
        }),
    })
end

return SkipAllButton
