--!strict
-- Root TextButton owns stroke / corner / shadow / scale.
-- ImageLabel is chrome only (no stroke, no animation).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.Parent.ImageIds)
local Shadow = require(script.Parent.Parent.util.Shadow)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useMountAppear = require(script.Parent.Parent.hooks.useMountAppear)

export type Props = {
    tone: theme.ActionTone,
    shine: theme.Shine?,
    label: string?,
    size: UDim2,
    aspectRatio: number?,
    -- When false, stretch PNG freely (inventory action rows). Default true for images.
    lockAspect: boolean?,
    image: string?,
    useGradient: boolean?,
    onActivated: (() -> ())?,
    disabled: boolean?,
    layoutOrder: number?,
    appearDelay: number?,
}

local function ActionButton(props: Props): React.Node
    local shine: theme.Shine = props.shine or "linear"
    local disabled = props.disabled == true
    local label = props.label or theme.ActionLabels[props.tone]
    local useGradient = props.useGradient == true
    local image: string? = if useGradient
        then nil
        else (props.image or ImageIds.Action[props.tone][shine])
    local aspect: number? = props.aspectRatio
    if aspect == nil and image ~= nil and props.lockAspect ~= false then
        aspect = ImageIds.ASPECT
    end

    local appearScale, appearTransparency = useMountAppear({
        delay = props.appearDelay or 0,
    })
    local hoverScale, handlers = useHoverPress({ disabled = disabled })
    local scale = appearScale * hoverScale

    local children: { [string]: React.Node } = {
        -- Motion + chrome modifiers live on the button itself
        Scale = React.createElement("UIScale", { Scale = scale }),
        Shadow = Shadow.element(theme.Shadow.button),
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(theme.Radius.button, 0),
        }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.button,
            Transparency = appearTransparency,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
        Label = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = label,
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            TextTransparency = appearTransparency,
            TextStrokeTransparency = 1,
            ZIndex = 2,
        }, {
            TextSizeConstraint = React.createElement("UITextSizeConstraint", {
                MinTextSize = 10,
                MaxTextSize = 72,
            }),
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                Transparency = appearTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        }),
    }

    if aspect ~= nil then
        children.Aspect = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = aspect,
            DominantAxis = Enum.DominantAxis.Width,
        })
    end

    if image ~= nil then
        children.Chrome = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = image,
            ImageTransparency = appearTransparency,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 0,
        })
    else
        local Gradient = require(script.Parent.Parent.util.Gradient)
        children.Gradient = Gradient.element(theme.ActionGradients[props.tone][shine])
    end

    return React.createElement("TextButton", {
        Size = props.size,
        BackgroundTransparency = if image ~= nil then 1 else appearTransparency,
        BackgroundColor3 = theme.Colors.white,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        LayoutOrder = props.layoutOrder,
        Active = not disabled,
        [React.Event.Activated] = if disabled then nil else props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, children)
end

return ActionButton
