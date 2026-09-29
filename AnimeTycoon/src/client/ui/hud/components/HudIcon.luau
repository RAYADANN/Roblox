--!strict
-- HUD icon button: image + label (SHOP / INDEX / REWARDS / REBIRTH).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    image: string,
    label: string,
    position: UDim2,
    onActivated: (() -> ())?,
}

local function HudIcon(props: Props): React.Node
    local I = SG.icons
    local scale, handlers = useHoverPress({ hoverScale = 1.08 })

    return React.createElement("ImageButton", {
        Size = I.buttonSize,
        Position = props.position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 2,
        [React.Event.Activated] = props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Icon = React.createElement("ImageLabel", {
            Size = I.icon.size,
            Position = I.icon.pos,
            AnchorPoint = I.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = props.image,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 1,
        }),
        Label = React.createElement(StrokeText, {
            text = props.label,
            strokeThickness = tokens.strokeIcon,
            size = I.label.size,
            position = I.label.pos,
            anchorPoint = I.label.anchor,
            uniformFitRef = "REWARDS",
            zIndex = 2,
        }),
    })
end

return HudIcon
