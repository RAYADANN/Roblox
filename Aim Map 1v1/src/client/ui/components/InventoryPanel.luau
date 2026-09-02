--!strict
-- Inventory mockup: white panel + left SimPop tabs + SimPop rarity grid.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignPanel = require(script.Parent.Parent.adapt.DesignPanel)
local InventoryGridLogic = require(ReplicatedStorage.shared.util.InventoryGridLogic)
local InventorySlot = require(script.Parent.InventorySlot)
local SimPopTab = require(script.Parent.Parent.simpop.SimPopTab)
local SkinDatabase = require(ReplicatedStorage.shared.data.SkinDatabase)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local playUiClick = require(script.Parent.Parent.util.playUiClick)
local theme = require(script.Parent.Parent.theme)
local useDesign = require(script.Parent.Parent.hooks.useDesign)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type TabId = "gun" | "case"

export type CaseItem = {
    id: string,
    name: string,
    rarity: string,
    image: string,
}

export type Props = {
    ownedSkinIds: { string },
    equippedSkinId: string,
    tab: TabId?,
    onTabChange: ((TabId) -> ())?,
    onEquipSkin: ((skinId: string) -> ())?,
    onClose: (() -> ())?,
    cases: { CaseItem }?,
}

local L = theme.Layout.inventory
local G = L.grid

local function ownedSet(ids: { string }): { [string]: boolean }
    local set: { [string]: boolean } = {}
    for _, id in ids do
        set[id] = true
    end
    return set
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
            Image = UiImageCatalog.hudIcon("close"),
            ScaleType = Enum.ScaleType.Fit,
            [React.Event.Activated] = playUiClick.wrapActivated(props.onActivated),
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Scale = React.createElement("UIScale", { Scale = hoverScale }),
        }),
    })
end

local function InventoryPanel(props: Props): React.Node
    local tab: TabId = props.tab or "gun"
    local owned = ownedSet(props.ownedSkinIds)
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

    local cases = props.cases
        or {
            {
                id = "case_standard",
                name = "Armory",
                rarity = "rare",
                image = UiImageCatalog.cases.standard,
            },
            {
                id = "case_epic",
                name = "Epic",
                rarity = "epic",
                image = UiImageCatalog.cases.epic,
            },
            {
                id = "case_legendary",
                name = "Legendary",
                rarity = "legendary",
                image = UiImageCatalog.cases.legendary,
            },
            {
                id = "case_mythic",
                name = "Mythic",
                rarity = "mythic",
                image = UiImageCatalog.cases.mythic,
            },
        }

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
            FillDirectionMaxCells = G.columns,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),
        Pad = React.createElement("UIPadding", {
            PaddingTop = padYB,
            PaddingBottom = padYB,
            PaddingLeft = padXB,
            PaddingRight = padXB,
        }),
    }

    if tab == "gun" then
        local skinImages = UiImageCatalog.skins :: { [string]: string }
        for i, skinId in SkinDatabase.listIds() do
            local def = SkinDatabase.get(skinId)
            if def then
                gridChildren[skinId] = React.createElement(InventorySlot, {
                    id = skinId,
                    name = def.name,
                    rarity = def.rarity,
                    image = skinImages[skinId],
                    owned = owned[skinId] == true,
                    equipped = props.equippedSkinId == skinId,
                    layoutOrder = i,
                    onEquip = function()
                        if props.onEquipSkin then
                            props.onEquipSkin(skinId)
                        end
                    end,
                })
            end
        end
    else
        for i, item in cases do
            gridChildren[item.id] = React.createElement(InventorySlot, {
                id = item.id,
                name = item.name,
                rarity = item.rarity,
                image = item.image,
                owned = true,
                equipped = false,
                iconScale = 2,
                layoutOrder = i,
                onEquip = function() end,
            })
        end
    end
    return React.createElement(DesignPanel, {
        size = L.size,
        position = L.position,
        anchor = L.anchor,
        children = {
            Tabs = React.createElement("Frame", {
                Size = UDim2.fromScale(L.tabW, L.tabStackH),
                Position = UDim2.fromScale(-L.tabInset, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                ZIndex = 4,
            }, {
                List = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(L.tabGap, 0),
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                Gun = React.createElement(SimPopTab, {
                    label = "GUN",
                    tone = "blue",
                    selected = tab == "gun",
                    size = UDim2.fromScale(1, 0.46),
                    layoutOrder = 1,
                    onActivated = function()
                        if props.onTabChange then
                            props.onTabChange("gun")
                        end
                    end,
                }),
                Case = React.createElement(SimPopTab, {
                    label = "CASE",
                    tone = "purple",
                    selected = tab == "case",
                    size = UDim2.fromScale(1, 0.46),
                    layoutOrder = 2,
                    onActivated = function()
                        if props.onTabChange then
                            props.onTabChange("case")
                        end
                    end,
                }),
            }),

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
                    Image = UiImageCatalog.hudIcon("inventory"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 5,
                }, {
                    Aspect = React.createElement("UIAspectRatioConstraint", {
                        AspectRatio = 1,
                        DominantAxis = Enum.DominantAxis.Height,
                    }),
                }),
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(0.45, 0, L.titleHeightScale, 0),
                    Position = UDim2.fromScale(0.1, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Text = "INVENTORY",
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                }, {
                    Outline = React.createElement("UIStroke", {
                        Color = theme.Colors.black,
                        Thickness = theme.Stroke.title,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    }),
                }),

                Close = React.createElement(CloseButton, {
                    onActivated = props.onClose,
                }),

                Scroll = React.createElement("ScrollingFrame", {
                    Size = UDim2.fromScale(L.scrollFill, L.scrollFill),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 6,
                    ScrollBarImageColor3 = theme.Colors.black,
                    CanvasSize = UDim2.fromOffset(0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
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

return InventoryPanel
