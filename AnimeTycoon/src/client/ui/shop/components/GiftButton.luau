--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    onActivated: (() -> ())?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
    layoutOrder: number?,
}

local function GiftButton(props: Props): React.Node
    local scale, handlers = useHoverPress({})

    return React.createElement("ImageButton", {
        Size = props.size or UDim2.fromScale(0.15, 0.25),
        Position = props.position or UDim2.fromScale(0.9, 0.85),
        AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = assets.giftBtn,
        ScaleType = Enum.ScaleType.Stretch,
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder,
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
        Icon = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(0.9, 0.9),
            Position = UDim2.fromScale(0.5, 0.45),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = assets.giftIcon,
            ScaleType = Enum.ScaleType.Fit,
        }),
    })
end

return GiftButton
