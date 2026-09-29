--!strict
-- Index modal: egg tabs + base pet grid + owned evolutions drill-in (Tycoon adaptivity).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignPanel = require(script.Parent.Parent.adapt.DesignPanel)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local IndexLogic = require(ReplicatedStorage.shared.util.IndexLogic)
local InventoryGridLogic = require(ReplicatedStorage.shared.util.InventoryGridLogic)
local PetViewport = require(script.Parent.PetViewport)
local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useDesign = require(script.Parent.Parent.hooks.useDesign)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    onClose: (() -> ())?,
    ownedEvolutions: IndexLogic.OwnedMap,
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

local function EggTabButton(props: {
    icon: string,
    selected: boolean,
    layoutOrder: number,
    cellW: number,
    onActivated: () -> (),
}): React.Node
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.08,
        pressScale = 0.94,
    })
    local hit = L.eggHitScale

    return React.createElement("Frame", {
        LayoutOrder = props.layoutOrder,
        Size = UDim2.fromScale(props.cellW, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 7,
    }, {
        Hit = React.createElement("ImageButton", {
            Size = UDim2.fromScale(hit, hit),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = props.icon,
            ImageTransparency = if props.selected then 0 else 0.35,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 7,
            [React.Event.Activated] = props.onActivated,
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
    modelName: string,
    unlocked: boolean,
    cardBg: string,
    layoutOrder: number,
    subtitle: string?,
    onActivated: (() -> ())?,
}

local function IndexCard(props: CardProps): React.Node
    local shineWidth = L.shineWidth
    local shineRef = shine.useShineRef({
        enabled = props.unlocked,
        intervalSec = 2.6,
        positionY = 0.5,
        shineWidth = shineWidth,
    })
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.04,
        pressScale = 0.96,
    })

    return React.createElement("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
        Hit = React.createElement("ImageButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = "",
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
            Bg = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = theme.Colors.indexCard,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Image = props.cardBg,
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
                Hero = React.createElement(PetViewport, {
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
                Sub = if props.subtitle
                    then React.createElement("TextLabel", {
                        Size = UDim2.fromScale(0.9, L.countH),
                        Position = UDim2.fromScale(0.5, L.countPad),
                        AnchorPoint = Vector2.new(0.5, 0),
                        BackgroundTransparency = 1,
                        Text = props.subtitle,
                        Font = theme.Font.display,
                        TextScaled = true,
                        TextColor3 = theme.Colors.white,
                        ZIndex = 6,
                    }, outlinedText("body"))
                    else nil,
            }),
        }),
    })
end

local function IndexPanel(props: Props): React.Node
    local owned = props.ownedEvolutions
    local eggId, setEggId = React.useState(IndexLogic.eggTabs(nil)[1].id)
    local selectedPetId, setSelectedPetId = React.useState(nil :: string?)
    local design = useDesign()

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

    local eggTabs = IndexLogic.eggTabs(eggId)
    local eggCount = math.max(#eggTabs, 1)
    local eggCellW = (1 - L.eggGap * math.max(eggCount - 1, 0)) / eggCount
    local showingEvolutions = selectedPetId ~= nil
    local baseCards = IndexLogic.baseCards(eggId, owned)
    local evoCards = if showingEvolutions
        then IndexLogic.evolutionCards(selectedPetId :: string, owned)
        else {}
    local cardBg =
        IconCatalog.byKey(if #baseCards > 0 then baseCards[1].cardBgKey else "CardStandart")

    local titleText = if showingEvolutions
        then string.upper(IndexLogic.petName(selectedPetId :: string))
        else "INDEX"

    local eggChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(L.eggGap, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, tab in eggTabs do
        eggChildren[tab.id] = React.createElement(EggTabButton, {
            icon = IconCatalog.byKey(tab.iconKey),
            selected = tab.selected,
            layoutOrder = i,
            cellW = eggCellW,
            onActivated = function()
                setEggId(tab.id)
                setSelectedPetId(nil)
            end,
        })
    end

    local gridChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIGridLayout", {
            CellSize = cellSizeB,
            CellPadding = cellPadB,
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = G.columns,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
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

    if showingEvolutions then
        for index, entry in evoCards do
            gridChildren[entry.id] = React.createElement(IndexCard, {
                name = entry.name,
                modelName = entry.modelName,
                unlocked = entry.unlocked,
                cardBg = cardBg,
                layoutOrder = index,
            })
        end
    else
        for index, entry in baseCards do
            gridChildren[entry.id] = React.createElement(IndexCard, {
                name = entry.name,
                modelName = entry.modelName,
                unlocked = entry.unlocked,
                cardBg = IconCatalog.byKey(entry.cardBgKey),
                subtitle = if entry.unlocked then `{entry.ownedCount}` else nil,
                layoutOrder = index,
                onActivated = function()
                    if entry.unlocked then
                        setSelectedPetId(entry.id)
                    end
                end,
            })
        end
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
                    Size = UDim2.new(0.35, 0, L.titleHeightScale, 0),
                    Position = UDim2.fromScale(0.09, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Text = titleText,
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                }, outlinedText("title")),

                Back = if showingEvolutions
                    then React.createElement("TextButton", {
                        Size = UDim2.fromScale(0.12, L.titleHeightScale * 0.7),
                        Position = UDim2.fromScale(0.42, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = theme.Colors.white,
                        BorderSizePixel = 0,
                        Text = "BACK",
                        Font = theme.Font.display,
                        TextScaled = true,
                        TextColor3 = theme.Colors.black,
                        AutoButtonColor = true,
                        ZIndex = 6,
                        [React.Event.Activated] = function()
                            setSelectedPetId(nil)
                        end,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(0.25, 0),
                        }),
                        Stroke = React.createElement("UIStroke", {
                            Color = theme.Colors.black,
                            Thickness = 3,
                        }),
                    })
                    else nil,

                -- Horizontal egg tabs (ScrollFrame later when many eggs).
                Eggs = React.createElement("Frame", {
                    Size = UDim2.fromScale(L.eggStripW, L.eggStripH),
                    Position = UDim2.fromScale(1 - L.eggStripPadRight, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = false,
                    ZIndex = 7,
                }, eggChildren),

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
