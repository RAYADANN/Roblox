--!strict
-- Index modal: Rebirth/Simpop chrome + Aim Map Inventory/Shop scroll grid.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignPanel = require(script.Parent.Parent.adapt.DesignPanel)
local HeroViewport = require(script.Parent.HeroViewport)
local HudContext = require(script.Parent.Parent.context.HudContext)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local IndexLogic = require(ReplicatedStorage.shared.util.IndexLogic)
local InventoryGridLogic = require(ReplicatedStorage.shared.util.InventoryGridLogic)
local playUiSound = require(script.Parent.Parent.util.playUiSound)
local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useDesign = require(script.Parent.Parent.hooks.useDesign)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    onClose: (() -> ())?,
}

local L = theme.Layout.index
local G = L.grid

local function outlinedText(kind: "title" | "body"): { [string]: React.Node }
    local isTitle = kind == "title"
    return {
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

type CardProps = {
    name: string,
    countLabel: string,
    modelName: string,
    unlocked: boolean,
    layoutOrder: number,
}

local function IndexCard(props: CardProps): React.Node
    local shineWidth = L.shineWidth
    local shineRef = shine.useShineRef({
        enabled = true,
        intervalSec = 2.6,
        positionY = 0.5,
        shineWidth = shineWidth,
    })
    local cardBg = IconCatalog.resolveImage(IconCatalog.ItemBackGround, "ItemBackGround")
    local sakura = IconCatalog.resolveImage(IconCatalog.SakuraIcon, "SakuraIcon")

    return React.createElement("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
        Bg = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = theme.Colors.indexCard,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Image = cardBg,
            ScaleType = Enum.ScaleType.Stretch,
            ClipsDescendants = true,
            ZIndex = 1,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(L.cardCornerScale, 0),
            }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = L.cardStroke,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            Hero = React.createElement(HeroViewport, {
                modelName = props.modelName,
                unlocked = props.unlocked,
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
                    ImageTransparency = 0.15,
                    ScaleType = Enum.ScaleType.Stretch,
                    ZIndex = 5,
                    ref = shineRef,
                }),
            }),
            Count = React.createElement("Frame", {
                Size = UDim2.fromScale(L.countW, L.countH),
                Position = UDim2.fromScale(1 - L.countPad, L.countPad),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 6,
            }, {
                Amount = React.createElement("TextLabel", {
                    Size = UDim2.fromScale(1 - L.countIconW, 1),
                    Position = UDim2.fromScale(0, 0.5),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Text = props.countLabel,
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 2,
                }, outlinedText("body")),
                Icon = React.createElement("ImageLabel", {
                    Size = UDim2.fromScale(L.countIconW, 1),
                    Position = UDim2.fromScale(1, 0.5),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = sakura,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1,
                }),
            }),
            Name = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, L.nameH),
                Position = UDim2.fromScale(0.5, 1 - L.namePad),
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundTransparency = 1,
                Text = props.name,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                ZIndex = 6,
            }, outlinedText("body")),
        }),
    })
end

local function IndexPanel(props: Props): React.Node
    local hud = React.useContext(HudContext).hud
    local cards = IndexLogic.cards(hud.indexMaxTier)
    local design = useDesign()

    -- Offset metrics in DesignRoot local px (AbsoluteSize is post-UIScale — divide first).
    local cellSizeB, setCellSize = React.useBinding(UDim2.fromOffset(0, 0))
    local cellPadB, setCellPad = React.useBinding(UDim2.fromOffset(0, 0))
    local padXB, setPadX = React.useBinding(UDim.new(0, 0))
    local padYB, setPadY = React.useBinding(UDim.new(0, 0))
    local lastSyncKeyRef = React.useRef("" :: string)

    local rowGap = G.rowGapScale
    local cellW, cellH =
        InventoryGridLogic.cellScale(G.columns, G.rowsVisible, G.padScale, G.gapScale, rowGap)
    cellH *= G.cellHeightMul

    local function syncGridMetrics(scroll: ScrollingFrame)
        local localX, localY = InventoryGridLogic.designPxFromAbsolute(
            scroll.AbsoluteSize.X,
            scroll.AbsoluteSize.Y,
            design.scale
        )
        local m = InventoryGridLogic.cellMetricsPx(
            localX,
            localY,
            cellW,
            cellH,
            G.padScale,
            G.gapScale,
            rowGap
        )
        if m.cellW <= 0 or m.cellH <= 0 then
            return
        end
        local key = string.format(
            "%.1f:%.1f:%.3f:%.3f:%.4f",
            m.cellW,
            m.cellH,
            m.gapX,
            m.gapY,
            design.scale
        )
        if lastSyncKeyRef.current == key then
            return
        end
        lastSyncKeyRef.current = key
        setCellSize(UDim2.fromOffset(m.cellW, m.cellH))
        setCellPad(UDim2.fromOffset(m.gapX, m.gapY))
        setPadX(UDim.new(0, m.padX))
        setPadY(UDim.new(0, m.padY))
    end

    local gridChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIGridLayout", {
            CellSize = cellSizeB,
            CellPadding = cellPadB,
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = G.columns,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Pad = React.createElement("UIPadding", {
            PaddingTop = padYB,
            PaddingBottom = padYB,
            PaddingLeft = padXB,
            PaddingRight = padXB,
        }),
    }
    for index, entry in cards do
        gridChildren[entry.id] = React.createElement(IndexCard, {
            name = entry.name,
            countLabel = entry.countLabel,
            modelName = entry.modelName,
            unlocked = entry.unlocked,
            layoutOrder = index,
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
                    Image = IconCatalog.Index,
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
                    Text = "INDEX",
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                }, outlinedText("title")),

                Close = React.createElement(CloseButton, {
                    onActivated = props.onClose,
                }),

                Body = React.createElement("ScrollingFrame", {
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
                    ClipsDescendants = true,
                    CanvasSize = UDim2.fromOffset(0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    ScrollBarThickness = L.scrollBarThickness,
                    ScrollBarImageColor3 = theme.Colors.black,
                    ScrollingEnabled = true,
                    ElasticBehavior = Enum.ElasticBehavior.Always,
                    ZIndex = 2,
                    [React.Change.AbsoluteSize] = function(scroll: ScrollingFrame)
                        syncGridMetrics(scroll)
                    end,
                    ref = function(scroll: ScrollingFrame?)
                        if scroll ~= nil then
                            syncGridMetrics(scroll)
                        end
                    end,
                }, {
                    -- Host AutomaticSize.Y includes UIPadding; Scale cells cannot do this safely.
                    Host = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, gridChildren),
                }),
            }),
        },
    })
end

return IndexPanel
