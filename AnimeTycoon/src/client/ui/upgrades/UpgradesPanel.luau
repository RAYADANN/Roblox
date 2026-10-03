--!strict
-- Upgrades panel: ScrollingFrame → Items (StarterGui.Upgrade).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.Parent.context.HudContext)
local SG = require(script.Parent.layout)
local UpgradeItemRow = require(script.Parent.components.UpgradeItemRow)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
local UpgradesWindow = require(script.Parent.UpgradesWindow)

export type Props = {
    onClose: () -> (),
    onBuyRobux: ((upgradeId: string) -> ())?,
}

type ScrollMetrics = {
    rowH: number,
    gapPx: number,
    padPx: number,
    canvasY: number,
}

local function UpgradesPanel(props: Props): React.Node
    local ctx = React.useContext(HudContext)
    local rows = UpgradeLogic.ordered()
    local n = #rows

    local metricsB, setMetrics = React.useBinding({
        rowH = 0,
        gapPx = 0,
        padPx = 0,
        canvasY = 0,
    } :: ScrollMetrics)
    local lastKeyRef = React.useRef("")

    local function syncMetrics(scroll: ScrollingFrame)
        local ax = scroll.AbsoluteSize.X
        local ay = scroll.AbsoluteSize.Y
        if ax <= 1 or ay <= 1 then
            return
        end
        local rowH = ay * SG.scroll.rowHFrac
        local gapPx = ay * SG.scroll.gapFrac
        local padPx = ay * SG.scroll.padFrac
        local canvasY = if n == 0
            then 2 * padPx
            else 2 * padPx + n * rowH + math.max(0, n - 1) * gapPx
        local key = string.format("%.1f:%.1f:%d", rowH, canvasY, n)
        if lastKeyRef.current == key then
            return
        end
        lastKeyRef.current = key
        setMetrics({
            rowH = rowH,
            gapPx = gapPx,
            padPx = padPx,
            canvasY = canvasY,
        })
    end

    local itemChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = metricsB:map(function(m: ScrollMetrics)
                return UDim.new(0, m.gapPx)
            end),
        }),
        Pad = React.createElement("UIPadding", {
            PaddingTop = metricsB:map(function(m: ScrollMetrics)
                return UDim.new(0, m.padPx)
            end),
            PaddingBottom = metricsB:map(function(m: ScrollMetrics)
                return UDim.new(0, m.padPx)
            end),
        }),
    }

    for i, entry in rows do
        itemChildren["U" .. entry.id] = React.createElement(UpgradeItemRow, {
            upgradeId = entry.id,
            title = entry.title,
            description = entry.description,
            icon = entry.icon,
            level = ctx.hud.upgrades[entry.id] or 0,
            coins = ctx.hud.coins,
            size = metricsB:map(function(m: ScrollMetrics)
                return UDim2.new(SG.row.widthScale, 0, 0, m.rowH)
            end),
            layoutOrder = i,
            onBuyCoins = ctx.buyUpgrade,
            onBuyRobux = props.onBuyRobux,
        })
    end

    return React.createElement(UpgradesWindow, {
        title = "Upgrades",
        onClose = props.onClose,
    }, {
        ScrollFrame = React.createElement("ScrollingFrame", {
            Size = SG.scroll.size,
            Position = SG.scroll.pos,
            AnchorPoint = SG.scroll.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = SG.scroll.barThickness,
            ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = metricsB:map(function(m: ScrollMetrics)
                return UDim2.fromOffset(0, m.canvasY)
            end),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            ZIndex = 2,
            ref = function(scroll: ScrollingFrame?)
                if scroll ~= nil then
                    syncMetrics(scroll)
                end
            end,
            [React.Change.AbsoluteSize] = function(scroll: ScrollingFrame)
                syncMetrics(scroll)
            end,
        }, {
            Items = React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, itemChildren),
        }),
    })
end

return UpgradesPanel
