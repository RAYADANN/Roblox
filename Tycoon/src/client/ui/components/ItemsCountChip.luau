--!strict
-- Bottom-center bag chip: ItemsCount art + backpack item score.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

export type Props = {
    count: number,
}

local L = theme.Layout.farm
local STROKE_TEAL = Color3.fromRGB(0, 39, 56)

local function textStroke(): React.Node
    return React.createElement("UIStroke", {
        Color = STROKE_TEAL,
        Thickness = 0.1,
        Transparency = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        LineJoinMode = Enum.LineJoinMode.Round,
        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
    })
end

local function ItemsCountChip(props: Props): React.Node
    local display = useFlipperSpring(props.count, MotionPresets.SPRING_NUMBER)
    local shown = math.floor(display + 0.5)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(L.itemsCountW, L.itemsCountH),
        Position = UDim2.fromScale(0.5, 1 - L.itemsCountPadBottom),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Aspect = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 1,
            DominantAxis = Enum.DominantAxis.Height,
        }),
        Art = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = IconCatalog.resolveImage(IconCatalog.ItemsCount, "ItemsCount"),
            ImageColor3 = Color3.new(1, 1, 1),
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 1,
        }),
        Amount = React.createElement("TextLabel", {
            Size = UDim2.fromScale(L.itemsCountTextW, L.itemsCountTextH),
            Position = UDim2.fromScale(0.5, L.itemsCountTextY),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = FormatMoney.comma(shown),
            Font = theme.Font.display,
            TextSize = 14,
            TextColor3 = theme.Colors.white,
            TextTransparency = 0,
            TextStrokeTransparency = 1,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 2,
        }, {
            UIStroke = textStroke(),
            SizeConstraint = React.createElement("UITextSizeConstraint", {
                MinTextSize = 18,
                MaxTextSize = 96,
            }),
        }),
    })
end

return ItemsCountChip
