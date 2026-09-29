--!strict
-- Rebirth modal: Figma 1027×552 board + Aim Map title/close on the panel edge.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignPanel = require(script.Parent.Parent.adapt.DesignPanel)
local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local RebirthLogic = require(ReplicatedStorage.shared.util.RebirthLogic)
local playUiSound = require(script.Parent.Parent.util.playUiSound)
local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useIdleBob = require(script.Parent.Parent.hooks.useIdleBob)

export type Props = {
    coins: number,
    rebirths: number,
    onClose: (() -> ())?,
    onRebirth: (() -> ())?,
    onSkip: (() -> ())?,
}

local L = theme.Layout.rebirth
local SHADOW_Y = theme.Space.xs

local function outlinedText(
    kind: "title" | "body",
    extra: { [string]: any }?
): { [string]: React.Node }
    local isTitle = kind == "title"
    local children: { [string]: React.Node } = {
        Outline = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = if isTitle then theme.Stroke.title else theme.Stroke.body,
            Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            LineJoinMode = Enum.LineJoinMode.Round,
            StrokeSizingMode = if isTitle
                then Enum.StrokeSizingMode.FixedSize
                else Enum.StrokeSizingMode.ScaledSize,
        }),
    }
    if extra then
        for key, node in extra do
            children[key] = node
        end
    end
    return children
end

local function CloseButton(props: { onActivated: (() -> ())? }): React.Node
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.08,
        pressScale = 0.92,
    })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(L.closeScale, L.closeScale),
        Position = UDim2.fromScale(1.04, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, {
        Aspect = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 1,
            DominantAxis = Enum.DominantAxis.Height,
        }),
        Hit = React.createElement("ImageButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = IconCatalog.Close,
            ScaleType = Enum.ScaleType.Fit,
            [React.Event.Activated] = function()
                playUiSound.play("ui_click")
                if props.onActivated then
                    props.onActivated()
                end
            end,
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Scale = React.createElement("UIScale", { Scale = hoverScale }),
        }),
    })
end

type ActionButtonProps = {
    label: string,
    image: string,
    layoutOrder: number,
    disabled: boolean?,
    onActivated: (() -> ())?,
}

local function ActionButton(props: ActionButtonProps): React.Node
    local disabled = props.disabled == true
    local hoverScale, handlers = useHoverPress({
        disabled = disabled,
        hoverScale = MotionPresets.HOVER_SCALE,
        pressScale = MotionPresets.PRESS_SCALE,
    })
    local shineWidth = L.shineWidth
    local shineRef = shine.useShineRef({
        enabled = not disabled,
        intervalSec = 2.2,
        positionY = 0.5,
        shineWidth = shineWidth,
    })
    local faceSize = UDim2.new(1, 0, 1, -SHADOW_Y)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(L.buttonW, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ClipsDescendants = false,
    }, {
        Scale = React.createElement("UIScale", { Scale = hoverScale }),

        Face = React.createElement("ImageButton", {
            Size = faceSize,
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = props.image,
            ImageTransparency = if disabled then 0.35 else 0,
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
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.panel * 0.55,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(L.buttonCornerScale, 0),
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
                    Size = UDim2.new(shineWidth, 0, 1.08, 0),
                    Position = UDim2.new(shine.startX(shineWidth), 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = IconCatalog.Shine,
                    ScaleType = Enum.ScaleType.Stretch,
                    ZIndex = 1,
                    ref = shineRef,
                }),
            }),
            Label = React.createElement(
                "TextLabel",
                {
                    Size = UDim2.fromScale(1, 0.72),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = props.label,
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Active = false,
                    ZIndex = 3,
                },
                outlinedText("body", {
                    SizeConstraint = React.createElement("UITextSizeConstraint", {
                        MinTextSize = 12,
                        MaxTextSize = 56,
                    }),
                })
            ),
        }),
    })
end

local function RebirthPanel(props: Props): React.Node
    local coins = props.coins
    local rebirths = props.rebirths
    local have, need = RebirthLogic.progress(coins, rebirths)
    local fraction = RebirthLogic.progressFraction(coins, rebirths)
    local canRebirth = RebirthLogic.canAfford(coins, rebirths)
    local rewardText = RebirthLogic.rewardLabel(rebirths)
    local progressText = `{FormatMoney.comma(have)}/{FormatMoney.comma(need)}`
    local coinBobRef = useIdleBob(0.5, L.rewardCoinY, L.rewardCoinBobPx)
    local progressFill = math.clamp(fraction, 0, 1)
    local fillTransparency: { NumberSequenceKeypoint }
    if progressFill <= 0 then
        fillTransparency = {
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 1),
        }
    elseif progressFill >= 1 then
        fillTransparency = {
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0),
        }
    else
        local edge = math.clamp(progressFill, 0.001, 0.999)
        fillTransparency = {
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(edge, 0),
            NumberSequenceKeypoint.new(math.min(edge + 0.002, 1), 1),
            NumberSequenceKeypoint.new(1, 1),
        }
    end

    return React.createElement(DesignPanel, {
        size = L.size,
        position = L.position,
        anchor = L.anchor,
        children = {
            Panel = React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = theme.Colors.white,
                BorderSizePixel = 0,
                ClipsDescendants = false,
                ZIndex = 1,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(L.panelCornerScale, 0),
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.panel,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),

                TitleIcon = React.createElement("ImageLabel", {
                    Size = UDim2.fromScale(L.titleIconScale, L.titleIconScale),
                    Position = UDim2.fromScale(L.titlePadX, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = IconCatalog.Rebirth,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 6,
                }, {
                    Aspect = React.createElement("UIAspectRatioConstraint", {
                        AspectRatio = 1,
                        DominantAxis = Enum.DominantAxis.Height,
                    }),
                }),
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(0.55, 0, L.titleHeightScale, 0),
                    Position = UDim2.fromScale(0.09, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Text = "REBIRTH",
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                }, outlinedText("title")),

                Close = React.createElement(CloseButton, {
                    onActivated = props.onClose,
                }),

                Body = React.createElement("Frame", {
                    Size = UDim2.new(
                        1 - L.contentPadX * 2,
                        0,
                        1 - L.contentTop - L.contentBottom,
                        0
                    ),
                    Position = UDim2.fromScale(0.5, L.contentTop),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                }, {
                    List = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(L.listPad, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),

                    RewardCard = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.rewardCardH),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 1,
                        ZIndex = 2,
                    }, {
                        Card = React.createElement("Frame", {
                            Size = UDim2.fromScale(L.rewardCardW, 1),
                            Position = UDim2.fromScale(0.5, 0.5),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            ZIndex = 1,
                        }, {
                            Aspect = React.createElement("UIAspectRatioConstraint", {
                                AspectRatio = L.rewardCardAspect,
                                DominantAxis = Enum.DominantAxis.Width,
                            }),
                            Bg = React.createElement("ImageLabel", {
                                Size = UDim2.fromScale(1, 1),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Image = IconCatalog.RewardBackground,
                                ScaleType = Enum.ScaleType.Stretch,
                                ZIndex = 1,
                            }, {
                                Corner = React.createElement("UICorner", {
                                    CornerRadius = UDim.new(0.08, 0),
                                }),
                                Stroke = React.createElement("UIStroke", {
                                    Color = theme.Colors.black,
                                    Thickness = theme.Stroke.panel * 0.55,
                                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                }),
                            }),
                            Label = React.createElement("TextLabel", {
                                Size = UDim2.fromScale(1, L.rewardLabelInCardH),
                                Position = UDim2.fromScale(0.5, 0),
                                AnchorPoint = Vector2.new(0.5, 0),
                                BackgroundTransparency = 1,
                                Text = rewardText,
                                Font = theme.Font.display,
                                TextScaled = true,
                                TextColor3 = theme.Colors.white,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                ZIndex = 3,
                            }, outlinedText("body")),
                            Coin = React.createElement("ImageLabel", {
                                Size = UDim2.fromScale(L.rewardCoinScale, L.rewardCoinScale),
                                Position = UDim2.fromScale(0.5, L.rewardCoinY),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Image = IconCatalog.Money,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 2,
                                ref = coinBobRef,
                            }),
                        }),
                    }),

                    ReqLabel = React.createElement("TextLabel", {
                        Size = UDim2.fromScale(1, L.reqLabelH),
                        BackgroundTransparency = 1,
                        Text = "Requirement",
                        Font = theme.Font.display,
                        TextScaled = true,
                        TextColor3 = theme.Colors.white,
                        LayoutOrder = 2,
                        ZIndex = 3,
                    }, outlinedText("body")),

                    Progress = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.progressH),
                        BackgroundColor3 = theme.Colors.progressTrack,
                        BorderSizePixel = 0,
                        ClipsDescendants = false,
                        LayoutOrder = 3,
                        ZIndex = 2,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(L.progressCornerScale, 0),
                        }),
                        Stroke = React.createElement("UIStroke", {
                            Color = theme.Colors.black,
                            Thickness = theme.Stroke.panel * 0.55,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        }),
                        Fill = React.createElement("ImageLabel", {
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Image = IconCatalog.ProgressLine,
                            ScaleType = Enum.ScaleType.Stretch,
                            ZIndex = 1,
                        }, {
                            Corner = React.createElement("UICorner", {
                                CornerRadius = UDim.new(L.progressCornerScale, 0),
                            }),
                            Mask = React.createElement("UIGradient", {
                                Transparency = NumberSequence.new(fillTransparency),
                                Rotation = 0,
                            }),
                        }),
                        Amount = React.createElement("TextLabel", {
                            Size = UDim2.fromScale(1, 0.85),
                            Position = UDim2.fromScale(0.5, 0.5),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            Text = progressText,
                            Font = theme.Font.display,
                            TextScaled = true,
                            TextColor3 = theme.Colors.white,
                            ZIndex = 3,
                        }, outlinedText("body")),
                    }),

                    ProgressGap = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.progressButtonGap),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 4,
                    }),

                    Buttons = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.buttonRowH),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 5,
                        ZIndex = 2,
                    }, {
                        List = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(L.buttonGap, 0),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        }),
                        Rebirth = React.createElement(ActionButton, {
                            label = "REBIRTH",
                            image = IconCatalog.RebirthButtonBackground,
                            layoutOrder = 1,
                            disabled = not canRebirth,
                            onActivated = props.onRebirth,
                        }),
                        Skip = React.createElement(ActionButton, {
                            label = "SKIP",
                            image = IconCatalog.SkipButtonBackground,
                            layoutOrder = 2,
                            disabled = false,
                            onActivated = props.onSkip,
                        }),
                    }),
                }),
            }),
        },
    })
end

return RebirthPanel
