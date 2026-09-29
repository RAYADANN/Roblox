--!strict
-- Index: табы + вертикальный грид 3 в ряд (Offset-ячейки, без AbsoluteContentSize-петли).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IndexCard = require(script.Parent.components.IndexCard)
local IndexWindow = require(script.Parent.IndexWindow)
local MockData = require(script.Parent.MockData)
local SG = require(script.Parent.layout)
local TabButton = require(script.Parent.components.TabButton)
local tokens = require(script.Parent.tokens)
local types = require(script.Parent.types)

export type Props = {
    tabs: { types.IndexTab }?,
    items: { types.IndexItem }?,
    initialTier: types.IndexTier?,
    onClose: () -> (),
    onSelectTier: ((types.IndexTier) -> ())?,
}

type GridMetrics = {
    cellW: number,
    cellH: number,
    gapX: number,
    gapY: number,
    padX: number,
    padY: number,
    canvasY: number,
}

local function IndexPanel(props: Props): React.Node
    local tabs = props.tabs or MockData.tabs()
    local items = props.items or MockData.items()
    local selected, setSelected = React.useState(props.initialTier or "normal")

    local filtered: { types.IndexItem } = {}
    for _, item in items do
        if item.tier == selected then
            table.insert(filtered, item)
        end
    end

    local metricsB, setMetrics = React.useBinding({
        cellW = 0,
        cellH = 0,
        gapX = 0,
        gapY = 0,
        padX = 0,
        padY = 0,
        canvasY = 0,
    } :: GridMetrics)
    local lastKeyRef = React.useRef("")
    local scrollRef = React.useRef(nil :: ScrollingFrame?)

    local function syncMetrics(scroll: ScrollingFrame)
        local ax = scroll.AbsoluteSize.X
        local ay = scroll.AbsoluteSize.Y
        if ax <= 1 or ay <= 1 then
            return
        end

        -- card.size — доли Window; Scroll ширина = Window, высота = content
        local scrollHFrac = 1 - SG.content.top - SG.content.bottom
        local cellW = ax * SG.card.size.X.Scale
        local cellH = ay * (SG.card.size.Y.Scale / scrollHFrac)
        local gapX = ax * SG.card.gap
        local gapY = ay * (SG.card.rowGap / scrollHFrac)
        local padX = ax * SG.card.pad
        local padY = ay * (SG.card.pad / scrollHFrac)
        local bottomPad = ay * (SG.card.bottomPad / scrollHFrac)

        local cols = SG.card.columns
        local n = #filtered
        local rows = if n == 0 then 0 else math.ceil(n / cols)
        local canvasY = if rows == 0
            then 2 * padY
            else 2 * padY + rows * cellH + (rows - 1) * gapY + bottomPad

        local key = string.format("%.1f:%.1f:%.1f:%d", cellW, cellH, canvasY, n)
        if lastKeyRef.current == key then
            return
        end
        lastKeyRef.current = key
        setMetrics({
            cellW = cellW,
            cellH = cellH,
            gapX = gapX,
            gapY = gapY,
            padX = padX,
            padY = padY,
            canvasY = canvasY,
        })
    end

    React.useEffect(function()
        lastKeyRef.current = ""
        local scroll = scrollRef.current
        if scroll ~= nil then
            syncMetrics(scroll)
        end
        return nil
    end, { selected, #filtered } :: { any })

    local tabChildren: { [string]: React.Node } = {}
    for i, tab in tabs do
        local x = SG.tab.firstX + (i - 1) * SG.tab.stepX
        tabChildren["T" .. tab.id] = React.createElement("Frame", {
            Size = SG.tab.size,
            Position = UDim2.fromScale(x, SG.tab.y),
            AnchorPoint = SG.tab.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, {
            Btn = React.createElement(TabButton, {
                text = tab.label,
                image = MockData.tabImage(tab.id),
                selected = selected == tab.id,
                layoutOrder = i,
                onActivated = function()
                    setSelected(tab.id)
                    if props.onSelectTier then
                        props.onSelectTier(tab.id)
                    end
                end,
            }),
        })
    end

    local gridChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIGridLayout", {
            CellSize = metricsB:map(function(m: GridMetrics): UDim2
                return UDim2.fromOffset(m.cellW, m.cellH)
            end),
            CellPadding = metricsB:map(function(m: GridMetrics): UDim2
                return UDim2.fromOffset(m.gapX, m.gapY)
            end),
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = SG.card.columns,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Pad = React.createElement("UIPadding", {
            PaddingTop = metricsB:map(function(m: GridMetrics): UDim
                return UDim.new(0, m.padY)
            end),
            PaddingBottom = metricsB:map(function(m: GridMetrics): UDim
                return UDim.new(0, m.padY)
            end),
            PaddingLeft = metricsB:map(function(m: GridMetrics): UDim
                return UDim.new(0, m.padX)
            end),
            PaddingRight = metricsB:map(function(m: GridMetrics): UDim
                return UDim.new(0, m.padX)
            end),
        }),
    }
    for i, item in filtered do
        gridChildren["C" .. item.id] = React.createElement("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = i,
            ZIndex = 2,
        }, {
            Card = React.createElement(IndexCard, {
                item = item,
                layoutOrder = i,
                fillParent = true,
            }),
        })
    end

    local children: { [string]: React.Node } = table.clone(tabChildren)
    children.CardScroll = React.createElement("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1 - SG.content.top - SG.content.bottom, 0),
        Position = UDim2.fromScale(0.5, SG.content.top),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = tokens.titleWhite,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = metricsB:map(function(m: GridMetrics): UDim2
            return UDim2.fromOffset(0, m.canvasY)
        end),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ElasticBehavior = Enum.ElasticBehavior.Always,
        ClipsDescendants = true,
        ZIndex = 2,
        ref = function(scroll: ScrollingFrame?)
            scrollRef.current = scroll
            if scroll ~= nil then
                syncMetrics(scroll)
            end
        end,
        [React.Change.AbsoluteSize] = function(scroll: ScrollingFrame)
            syncMetrics(scroll)
        end,
    }, gridChildren)

    return React.createElement(IndexWindow, {
        title = "Index",
        onClose = props.onClose,
    }, children)
end

return IndexPanel
