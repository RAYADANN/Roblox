--!strict
-- Header без Close (в StarterGui только Cancel / Double).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)

export type Props = {
    title: string,
}

local function OfflineHeader(props: Props): React.Node
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
    })
end

return OfflineHeader
