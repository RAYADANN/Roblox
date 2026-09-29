--!strict
-- Cancel / Double кнопки + Robux-цена (AutomaticSize группа).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type CancelProps = {
    onActivated: () -> (),
}

export type DoubleProps = {
    price: number,
    onActivated: () -> (),
}

local function CancelButton(props: CancelProps): React.Node
    local scale, handlers = useHoverPress({})
    local C = SG.cancel

    return React.createElement("ImageButton", {
        Size = C.size,
        Position = C.pos,
        AnchorPoint = C.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = assets.cancelBtn,
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
            text = "NO THANKS!",
            strokeThickness = tokens.strokeText,
            size = C.labelSize,
            position = UDim2.fromScale(0.5, 0.5),
            anchorPoint = Vector2.new(0.5, 0.5),
            zIndex = 2,
        }),
    })
end

local function DoubleButton(props: DoubleProps): React.Node
    local scale, handlers = useHoverPress({})
    local D = SG.doubleBtn

    return React.createElement("ImageButton", {
        Size = D.size,
        Position = D.pos,
        AnchorPoint = D.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = assets.doubleBtn,
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
        Badge = React.createElement(StrokeText, {
            text = "x2",
            strokeThickness = tokens.strokeText,
            size = D.badge.size,
            position = D.badge.pos,
            anchorPoint = D.badge.anchor,
            zIndex = 2,
        }),
        Label = React.createElement(StrokeText, {
            text = "DOUBLE IT!",
            strokeThickness = tokens.strokeText,
            size = D.label.size,
            position = D.label.pos,
            anchorPoint = D.label.anchor,
            zIndex = 2,
        }),
        Price = React.createElement("Frame", {
            Size = D.price.size,
            Position = D.price.pos,
            AnchorPoint = D.price.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            -- Как StarterGui DoubleButton.Frame: Icon @0.35, Text @0.55
            Icon = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(0.3, 1),
                Position = UDim2.fromScale(0.3, 0.5),
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
                size = UDim2.fromScale(0.55, 1),
                position = UDim2.fromScale(0.68, 0.5),
                anchorPoint = Vector2.new(0.5, 0.5),
                textWrapped = false,
                textXAlignment = Enum.TextXAlignment.Left,
                zIndex = 2,
            }),
        }),
    })
end

return {
    CancelButton = CancelButton,
    DoubleButton = DoubleButton,
}
