--!strict
-- Root TextButton owns stroke / corner / shadow / scale.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Gradient = require(script.Parent.Parent.util.Gradient)
local Shadow = require(script.Parent.Parent.util.Shadow)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useMountAppear = require(script.Parent.Parent.hooks.useMountAppear)

export type Props = {
    size: UDim2,
    shine: theme.Shine?,
    onActivated: (() -> ())?,
    layoutOrder: number?,
    appearDelay: number?,
}

local function CloseButton(props: Props): React.Node
    local shine: theme.Shine = props.shine or "linear"
    local grad = theme.CloseXGradients[shine]
    local appearScale, appearTransparency = useMountAppear({
        delay = props.appearDelay or 0,
        fromScale = 0.5,
    })
    local hoverScale, handlers = useHoverPress({})
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
        [React.Event.Activated] = props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(theme.Radius.closeX, 0),
        }),
        Shadow = Shadow.element(theme.Shadow.closeX),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.closeX,
            Transparency = appearTransparency,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
        Gradient = Gradient.element(grad),
        Label = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "X",
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            TextTransparency = appearTransparency,
            TextStrokeTransparency = 1,
            ZIndex = 2,
        }, {
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                Transparency = appearTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        }),
    })
end

return CloseButton
