--!strict
-- Root owns stroke / scale; no CanvasGroup wrapper.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Gradient = require(script.Parent.Parent.util.Gradient)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useMountAppear = require(script.Parent.Parent.hooks.useMountAppear)

export type Props = {
    rarity: theme.SlotRarity,
    size: UDim2,
    layoutOrder: number?,
    appearDelay: number?,
    children: React.Node?,
}

local function Slot(props: Props): React.Node
    local grad = theme.SlotGradients[props.rarity]
    local appearScale, appearTransparency = useMountAppear({
        delay = props.appearDelay or 0,
        fromScale = 0.7,
    })
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.06,
        pressScale = 0.96,
    })
    local scale = appearScale * hoverScale

    return React.createElement("TextButton", {
        Size = props.size,
        BackgroundColor3 = theme.Colors.white,
        BackgroundTransparency = appearTransparency,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        LayoutOrder = props.layoutOrder,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(theme.Radius.slot, 0),
        }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.stroke,
            Thickness = theme.Stroke.slot,
            Transparency = appearTransparency,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
        Gradient = Gradient.element(grad),
        Content = props.children,
    })
end

return Slot
