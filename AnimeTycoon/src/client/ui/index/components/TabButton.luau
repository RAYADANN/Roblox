--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    text: string,
    image: string,
    selected: boolean,
    layoutOrder: number,
    onActivated: () -> (),
}

local function TabButton(props: Props): React.Node
    local scale, handlers = useHoverPress({})
    local visualScale = if props.selected then scale * 1.12 else scale

    return React.createElement("ImageButton", {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = props.image,
        ScaleType = Enum.ScaleType.Stretch,
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder,
        ImageTransparency = if props.selected then 0 else 0.12,
        [React.Event.Activated] = props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = visualScale }),
        Stroke = React.createElement("UIStroke", {
            Color = tokens.titleShadow,
            Thickness = tokens.strokeBtn,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
        Label = React.createElement(StrokeText, {
            text = props.text,
            strokeThickness = tokens.strokeText,
            size = SG.tab.labelSize,
            position = SG.tab.labelPos,
            anchorPoint = Vector2.new(0.5, 0.5),
            zIndex = 2,
        }),
    })
end

return TabButton
