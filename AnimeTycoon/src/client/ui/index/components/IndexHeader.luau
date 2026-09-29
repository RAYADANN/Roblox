--!strict
-- Index header: blue title bar + book icon pinned to header (не Stage).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    title: string,
    onClose: () -> (),
}

local function IndexHeader(props: Props): React.Node
    local scale, handlers = useHoverPress({})

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    }, {
        Bar = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = assets.titleBar,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = tokens.titleShadow,
                Thickness = tokens.strokeTitle,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
        }),
        Icon = React.createElement("ImageLabel", {
            Size = SG.icon.size,
            Position = SG.icon.pos,
            AnchorPoint = SG.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = assets.icon,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 5,
        }, {
            Aspect = React.createElement("UIAspectRatioConstraint", {
                AspectRatio = 1,
                DominantAxis = Enum.DominantAxis.Height,
            }),
        }),
        Shadow = React.createElement(StrokeText, {
            text = props.title,
            color = tokens.titleShadow,
            strokeThickness = tokens.strokeShadow,
            size = SG.titleShadow.size,
            position = SG.titleShadow.pos,
            anchorPoint = SG.titleShadow.anchor,
            uniformFitRef = "Rewards",
            zIndex = 2,
        }),
        Title = React.createElement(StrokeText, {
            text = props.title,
            strokeThickness = tokens.strokeTitle,
            size = SG.titleText.size,
            position = SG.titleText.pos,
            anchorPoint = SG.titleText.anchor,
            uniformFitRef = "Rewards",
            zIndex = 3,
        }),
        Close = React.createElement("Frame", {
            Size = SG.close.size,
            Position = SG.close.pos,
            AnchorPoint = SG.close.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 50,
        }, {
            Hit = React.createElement("ImageButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = assets.close,
                ScaleType = Enum.ScaleType.Stretch,
                AutoButtonColor = false,
                ZIndex = 51,
                [React.Event.Activated] = props.onClose,
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
            }),
        }),
    })
end

return IndexHeader
