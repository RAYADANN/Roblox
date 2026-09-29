--!strict
-- Shop modal (Aim Map shell): banners + coin pack grid. UI only — mock buy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignPanel = require(script.Parent.Parent.adapt.DesignPanel)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local InventoryGridLogic = require(ReplicatedStorage.shared.util.InventoryGridLogic)
local ShopLogic = require(ReplicatedStorage.shared.util.ShopLogic)
local ShopProductCard = require(script.Parent.ShopProductCard)
local theme = require(script.Parent.Parent.theme)
local useDesign = require(script.Parent.Parent.hooks.useDesign)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    progress: ShopLogic.Progress?,
    onBuyProduct: ((productId: string) -> ())?,
    onClose: (() -> ())?,
}

local L = theme.Layout.shop

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

local function shineFor(kind: ShopLogic.LayoutKind): number
    if kind == "banner" then
        return 0.14
    end
    return 0.28
end

local function ShopPanel(props: Props): React.Node
    local design = useDesign()
    local cards = ShopLogic.products(props.progress)
    local banners = ShopLogic.banners(cards)
    local packs = ShopLogic.packs(cards)

    local bannerSizeB, setBannerSize = React.useBinding(UDim2.new(1, 0, 0, 0))
    local packSizeB, setPackSize = React.useBinding(UDim2.fromOffset(0, 0))
    local productPadB, setProductPad = React.useBinding(UDim2.fromOffset(0, 0))
    local listPadB, setListPad = React.useBinding(UDim.new(0, 0))
    local padXB, setPadX = React.useBinding(UDim.new(0, 0))
    local padYB, setPadY = React.useBinding(UDim.new(0, 0))
    local lastSyncKeyRef = React.useRef("" :: string)

    local function syncScrollMetrics(scroll: ScrollingFrame)
        local localX, localY = InventoryGridLogic.designPxFromAbsolute(
            scroll.AbsoluteSize.X,
            scroll.AbsoluteSize.Y,
            design.scale
        )
        local padX = localX * L.contentPad
        local padY = localY * L.contentPad
        local gap = localY * L.sectionGap
        local productGap = localX * L.productGap
        local innerW = math.max(0, localX - 2 * padX)
        local bannerAspect = if #banners > 0 then banners[1].aspectRatio else (1121 / 260)
        local bannerH = innerW / bannerAspect
        local cols = math.max(1, L.productCols)
        local packW = (innerW - (cols - 1) * productGap) / cols
        local packAspect = if #packs > 0 then packs[1].aspectRatio else 1
        local packH = packW / packAspect
        if bannerH <= 0 or packW <= 0 then
            return
        end
        local key =
            string.format("%.1f:%.1f:%.1f:%.1f:%.4f", bannerH, packW, packH, gap, design.scale)
        if lastSyncKeyRef.current == key then
            return
        end
        lastSyncKeyRef.current = key
        setBannerSize(UDim2.new(1, 0, 0, bannerH))
        setPackSize(UDim2.fromOffset(packW, packH))
        setProductPad(UDim2.fromOffset(productGap, productGap))
        setListPad(UDim.new(0, gap))
        setPadX(UDim.new(0, padX))
        setPadY(UDim.new(0, padY))
    end

    local listChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = listPadB,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Pad = React.createElement("UIPadding", {
            PaddingTop = padYB,
            PaddingBottom = padYB,
            PaddingLeft = padXB,
            PaddingRight = padXB,
        }),
    }

    local bannerChildren: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = listPadB,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, product in banners do
        bannerChildren[product.id] = React.createElement("Frame", {
            Size = bannerSizeB,
            BackgroundTransparency = 1,
            LayoutOrder = i,
        }, {
            Card = React.createElement(ShopProductCard, {
                title = product.title,
                plateImage = IconCatalog.byKey(product.plateKey),
                heroImage = if product.heroKey then IconCatalog.byKey(product.heroKey) else nil,
                shineWidth = shineFor(product.kind),
                price = product.priceRobux,
                kind = product.kind,
                description = product.description,
                onBuy = function()
                    if props.onBuyProduct then
                        props.onBuyProduct(product.id)
                    end
                end,
            }),
        })
    end

    local packChildren: { [string]: React.Node } = {
        Grid = React.createElement("UIGridLayout", {
            CellSize = packSizeB,
            CellPadding = productPadB,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirectionMaxCells = L.productCols,
        }),
    }
    for i, product in packs do
        packChildren[product.id] = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            LayoutOrder = i,
        }, {
            Card = React.createElement(ShopProductCard, {
                title = product.title,
                plateImage = IconCatalog.byKey(product.plateKey),
                heroImage = if product.heroKey then IconCatalog.byKey(product.heroKey) else nil,
                shineWidth = shineFor(product.kind),
                price = product.priceRobux,
                kind = product.kind,
                onBuy = function()
                    if props.onBuyProduct then
                        props.onBuyProduct(product.id)
                    end
                end,
            }),
        })
    end

    listChildren.Banners = React.createElement("Frame", {
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, bannerChildren)

    listChildren.Packs = React.createElement("Frame", {
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, packChildren)

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
                    Image = IconCatalog.Shop,
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
                    Position = UDim2.fromScale(0.12, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Text = "SHOP",
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
                        syncScrollMetrics(scroll)
                    end,
                    ref = function(scroll: ScrollingFrame?)
                        if scroll ~= nil then
                            syncScrollMetrics(scroll)
                        end
                    end,
                }, {
                    Host = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, listChildren),
                }),
            }),
        },
    })
end

return ShopPanel
