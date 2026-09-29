--!strict
-- Rebirth modal: perk row + Tycoon-style progress + Skip / Rebirth (ShowRoom assets).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignPanel = require(script.Parent.Parent.adapt.DesignPanel)
local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local RebirthDatabase = require(ReplicatedStorage.shared.data.RebirthDatabase)
local RebirthLogic = require(ReplicatedStorage.shared.util.RebirthLogic)
local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    coins: number,
    rebirths: number,
    onClose: (() -> ())?,
    onRebirth: (() -> ())?,
    onSkip: (() -> ())?,
}

local L = theme.Layout.rebirth
local SHADOW_Y = 4

local function outlinedText(
    kind: "title" | "body",
    extra: { [string]: React.Node }?
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
    widthScale: number,
    heightScale: number?,
    disabled: boolean?,
    shine: boolean?,
    -- When false, keep full-bright image even if disabled.
    dimWhenDisabled: boolean?,
    -- Hover/press even when click is disabled (Rebirth afford gate).
    hoverWhenDisabled: boolean?,
    onActivated: (() -> ())?,
}

local function ActionButton(props: ActionButtonProps): React.Node
    local disabled = props.disabled == true
    local dimWhenDisabled = props.dimWhenDisabled ~= false
    local hoverWhenDisabled = props.hoverWhenDisabled == true
    local shineOn = props.shine == true
    local heightScale = props.heightScale or 1
    local hoverScale, handlers = useHoverPress({
        disabled = if hoverWhenDisabled then false else disabled,
        hoverScale = MotionPresets.HOVER_SCALE,
        pressScale = MotionPresets.PRESS_SCALE,
    })
    local shineWidth = L.shineWidth
    local shineRef = shine.useShineRef({
        enabled = shineOn,
        intervalSec = 2.2,
        positionY = 0.5,
        shineWidth = shineWidth,
    })
    local faceSize = UDim2.new(1, 0, heightScale, -SHADOW_Y)
    local dim = disabled and dimWhenDisabled

    return React.createElement("Frame", {
        Size = UDim2.fromScale(props.widthScale, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ClipsDescendants = false,
    }, {
        Scale = React.createElement("UIScale", { Scale = hoverScale }),

        Face = React.createElement("ImageButton", {
            Size = faceSize,
            Position = UDim2.fromScale(0, 0.5),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = props.image,
            ImageColor3 = if dim then Color3.fromRGB(170, 170, 170) else theme.Colors.white,
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
            Active = not disabled,
            [React.Event.Activated] = if disabled or props.onActivated == nil
                then nil
                else props.onActivated,
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = if disabled then nil else handlers.onMouseDown,
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
            ShineClip = if shineOn
                then React.createElement("Frame", {
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
                        ImageTransparency = 0.35,
                        ScaleType = Enum.ScaleType.Stretch,
                        ZIndex = 1,
                        ref = shineRef,
                    }),
                })
                else nil,
            Label = React.createElement("TextLabel", {
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
            }, outlinedText("body")),
        }),
    })
end

local function PerkIcon(props: {
    image: string,
    phaseOffset: number,
}): React.Node
    local baseY = L.perkIconY
    local iconY, setIconY = React.useBinding(baseY)

    React.useEffect(function()
        local t0 = os.clock()
        local conn = RunService.RenderStepped:Connect(function()
            local phase = (os.clock() - t0) * L.perkIconBobHz * math.pi * 2 + props.phaseOffset
            setIconY(baseY + math.sin(phase) * L.perkIconBobAmp)
        end)
        return function()
            conn:Disconnect()
        end
    end, { baseY, props.phaseOffset })

    return React.createElement("ImageLabel", {
        Size = UDim2.fromScale(L.perkIconScale, L.perkIconScale),
        Position = iconY:map(function(y: number)
            return UDim2.fromScale(0.5, y)
        end),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = props.image,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 2,
    })
end

local function PerkCard(props: {
    title: string,
    cardBg: string,
    icon: string,
    layoutOrder: number,
    cellW: number,
}): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(props.cellW, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ClipsDescendants = false,
    }, {
        Card = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Aspect = React.createElement("UIAspectRatioConstraint", {
                AspectRatio = L.perkAspect,
                DominantAxis = Enum.DominantAxis.Width,
            }),
            Bg = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = props.cardBg,
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 1,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(L.perkCornerScale, 0),
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.panel * 0.55,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            }),
            Label = React.createElement("TextLabel", {
                Size = UDim2.fromScale(0.94, L.perkLabelH),
                Position = UDim2.fromScale(0.5, 0.04),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = props.title,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 3,
            }, {
                Outline = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.body,
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    LineJoinMode = Enum.LineJoinMode.Round,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
                SizeConstraint = React.createElement("UITextSizeConstraint", {
                    MinTextSize = 8,
                    MaxTextSize = L.perkLabelMaxText,
                }),
            }),
            Icon = React.createElement(PerkIcon, {
                image = props.icon,
                phaseOffset = (props.layoutOrder - 1) * 0.7,
            }),
        }),
    })
end

local function fillMask(progressFill: number): { NumberSequenceKeypoint }
    if progressFill <= 0 then
        return {
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 1),
        }
    end
    if progressFill >= 1 then
        return {
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0),
        }
    end
    local edge = math.clamp(progressFill, 0.001, 0.999)
    return {
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(edge, 0),
        NumberSequenceKeypoint.new(math.min(edge + 0.002, 1), 1),
        NumberSequenceKeypoint.new(1, 1),
    }
end

local function RebirthPanel(props: Props): React.Node
    local coins = props.coins
    local rebirths = props.rebirths
    local have, need = RebirthLogic.progress(coins, rebirths)
    local fraction = RebirthLogic.progressFraction(coins, rebirths)
    local canRebirth = RebirthLogic.canAfford(coins, rebirths)
    local progressText = `{FormatMoney.comma(have)}/{FormatMoney.comma(need)}`
    local progressFill = math.clamp(fraction, 0, 1)
    local fillTransparency = fillMask(progressFill)

    local perks = RebirthDatabase.Perks
    local n = #perks
    local gapTotal = if n > 1 then L.perkGap * (n - 1) else 0
    local cellW = if n > 0 then (1 - gapTotal) / n else 1

    local perkChildren: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(L.perkGap, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, perk in perks do
        local title = if perk.dynamicCoinTitle
            then RebirthLogic.coinRewardLabel(rebirths)
            else perk.title
        perkChildren[`P{i}`] = React.createElement(PerkCard, {
            title = title,
            cardBg = IconCatalog.byKey(perk.cardBgKey),
            icon = IconCatalog.byKey(perk.iconKey),
            layoutOrder = i,
            cellW = cellW,
        })
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
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(L.listPad, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),

                    Receive = React.createElement(
                        "TextLabel",
                        {
                            Size = UDim2.fromScale(1, L.receiveH),
                            BackgroundTransparency = 1,
                            Text = "You will receive",
                            Font = theme.Font.display,
                            TextScaled = true,
                            TextColor3 = theme.Colors.white,
                            LayoutOrder = 1,
                            ZIndex = 3,
                        },
                        outlinedText("body", {
                            SizeConstraint = React.createElement("UITextSizeConstraint", {
                                MinTextSize = 22,
                                MaxTextSize = L.receiveMaxText,
                            }),
                        })
                    ),

                    Perks = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.perkRowH),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 2,
                        ZIndex = 2,
                    }, perkChildren),

                    PerkProgressGap = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.perkProgressGap),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 3,
                    }),

                    Requirement = React.createElement("TextLabel", {
                        Size = UDim2.fromScale(1, L.reqLabelH),
                        BackgroundTransparency = 1,
                        Text = "Requirement",
                        Font = theme.Font.display,
                        TextScaled = true,
                        TextColor3 = theme.Colors.white,
                        LayoutOrder = 4,
                        ZIndex = 3,
                    }, outlinedText("body")),

                    Progress = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.progressH),
                        BackgroundColor3 = theme.Colors.progressTrack,
                        BorderSizePixel = 0,
                        ClipsDescendants = false,
                        LayoutOrder = 5,
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
                        LayoutOrder = 6,
                    }),

                    Buttons = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, L.buttonRowH),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 7,
                        ZIndex = 2,
                    }, {
                        List = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(L.buttonGap, 0),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        }),
                        Skip = React.createElement(ActionButton, {
                            label = "SKIP",
                            image = IconCatalog.SkipButton,
                            layoutOrder = 2,
                            widthScale = L.skipButtonW,
                            heightScale = L.skipButtonH,
                            disabled = false,
                            shine = true,
                            onActivated = props.onSkip,
                        }),
                        Rebirth = React.createElement(ActionButton, {
                            label = "REBIRTH",
                            image = IconCatalog.RebirthButton,
                            layoutOrder = 1,
                            widthScale = L.rebirthButtonW,
                            heightScale = 1,
                            disabled = not canRebirth,
                            dimWhenDisabled = false,
                            hoverWhenDisabled = true,
                            shine = false,
                            onActivated = props.onRebirth,
                        }),
                    }),
                }),
            }),
        },
    })
end

return RebirthPanel
