--!strict
-- Pill money offer button: MoneyButton art + Buton25Rooms text gradient + SimPop shine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    amount: number,
    size: UDim2?,
    layoutOrder: number?,
    disabled: boolean?,
    shineIntervalSec: number?,
    onActivated: (() -> ())?,
}

local farmLayout = theme.Layout.farm
local SHINE_WIDTH = farmLayout.moneyOfferShineWidth

local function moneyTextGradient(): React.Node
    local def = theme.Gradients.moneyButtonText
    local keys = table.create(#def.keypoints)
    for i, stop in def.keypoints do
        keys[i] = ColorSequenceKeypoint.new(stop.t, stop.c)
    end
    return React.createElement("UIGradient", {
        Color = ColorSequence.new(keys),
        Rotation = def.rotation,
    })
end

local function MoneyButton(props: Props): React.Node
    local disabled = props.disabled == true
    local bg = IconCatalog.resolveImage(IconCatalog.MoneyButton, "MoneyButton")

    local hoverScale, handlers = useHoverPress({
        disabled = disabled,
        hoverScale = MotionPresets.HOVER_SCALE,
        pressScale = MotionPresets.PRESS_SCALE,
    })

    local shineRef = shine.useShineRef({
        enabled = not disabled,
        intervalSec = props.shineIntervalSec or 2,
        positionY = 0.5,
        shineWidth = SHINE_WIDTH,
    })

    return React.createElement("Frame", {
        Size = props.size or UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        LayoutOrder = props.layoutOrder,
    }, {
        Scale = React.createElement("UIScale", { Scale = hoverScale }),
        Face = React.createElement("ImageButton", {
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = bg,
            ImageColor3 = Color3.new(1, 1, 1),
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
            Active = not disabled,
            [React.Event.Activated] = if disabled or props.onActivated == nil
                then nil
                else props.onActivated,
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = theme.Radius.pill,
            }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.moneyButtonStroke,
                Thickness = theme.Stroke.moneyButton,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            ShineClip = React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Active = false,
                ZIndex = 5,
            }, {
                Shine = React.createElement("ImageLabel", {
                    Size = UDim2.new(SHINE_WIDTH, 0, 1.08, 0),
                    Position = UDim2.new(shine.startX(SHINE_WIDTH), 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = IconCatalog.Shine,
                    ScaleType = Enum.ScaleType.Stretch,
                    ZIndex = 1,
                    ref = shineRef,
                }),
            }),
            Label = React.createElement("TextLabel", {
                -- TextScaled fills this box; height < 1 leaves pill vertical padding.
                Size = UDim2.fromScale(1, farmLayout.moneyOfferTextH),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = `$` .. FormatMoney.comma(props.amount),
                Font = Enum.Font.FredokaOne,
                TextSize = 14,
                TextColor3 = theme.Colors.white,
                TextTransparency = 0,
                TextStrokeTransparency = 1,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Active = false,
                ZIndex = 3,
            }, {
                TextSizeConstraint = React.createElement("UITextSizeConstraint", {
                    MinTextSize = 10,
                    MaxTextSize = 64,
                }),
                Outline = React.createElement("UIStroke", {
                    Color = theme.Colors.outlineDark,
                    Thickness = theme.Stroke.moneyButtonText,
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    LineJoinMode = Enum.LineJoinMode.Round,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
                Grad = moneyTextGradient(),
            }),
        }),
    })
end

return MoneyButton
