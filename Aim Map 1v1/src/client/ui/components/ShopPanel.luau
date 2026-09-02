--!strict
-- Shop mockup: inventory shell + scrollable case offer cards.
-- Scroll metrics: same Offset + AutomaticSize pattern as InventoryPanel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignPanel = require(script.Parent.Parent.adapt.DesignPanel)
local InventoryGridLogic = require(ReplicatedStorage.shared.util.InventoryGridLogic)
local ShopOfferCard = require(script.Parent.ShopOfferCard)
local ShopProductCard = require(script.Parent.ShopProductCard)
local SimPopLongBlock = require(script.Parent.Parent.simpop.block.SimPopLongBlock)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local playUiClick = require(script.Parent.Parent.util.playUiClick)
local theme = require(script.Parent.Parent.theme)
local useDesign = require(script.Parent.Parent.hooks.useDesign)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Offer = {
    id: string,
    title: string,
    caseImage: string,
    plateTone: SimPopLongBlock.LongTone?,
    drops: { ShopOfferCard.DropPreview },
    buys: { ShopOfferCard.BuyOption },
}

export type Product = {
    id: string,
    title: string,
    itemKey: UiImageCatalog.ShopItemKey,
    price: number,
    kind: ShopProductCard.LayoutKind,
    featured: boolean?,
}

export type Props = {
    offers: { Offer }?,
    products: { Product }?,
    onBuy: ((offerId: string, qty: number) -> ())?,
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

local function defaultOffers(): { Offer }
    local buys: { ShopOfferCard.BuyOption } = {
        { qty = 5, price = 199, featured = true },
        { qty = 3, price = 199, featured = false },
        { qty = 1, price = 199, featured = false },
    }

    local dropRarities: { string } = { "common", "uncommon", "rare", "legendary" }

    local function dropsFor(
        prefix: string,
        name: string,
        skinImage: string
    ): { ShopOfferCard.DropPreview }
        local list: { ShopOfferCard.DropPreview } = {}
        for i = 1, 4 do
            table.insert(list, {
                id = `{prefix}_{i}`,
                name = name,
                chanceLabel = "10%",
                rarity = dropRarities[i],
                image = skinImage,
            })
        end
        return list
    end

    return {
        {
            id = "case_rare",
            title = "Rare Case",
            caseImage = UiImageCatalog.cases.rare,
            plateTone = "blue",
            drops = dropsFor("rare", "Frost", UiImageCatalog.skins.usp_frost),
            buys = buys,
        },
        {
            id = "case_epic",
            title = "Epic Case",
            caseImage = UiImageCatalog.cases.epic,
            plateTone = "purple",
            drops = dropsFor("epic", "Neon", UiImageCatalog.skins.usp_neon),
            buys = buys,
        },
        {
            id = "case_legendary",
            title = "Legendary Case",
            caseImage = UiImageCatalog.cases.legendary,
            plateTone = "orange",
            drops = dropsFor("leg", "Ember", UiImageCatalog.skins.usp_ember),
            buys = buys,
        },
        {
            id = "case_mythic",
            title = "Mythic Case",
            caseImage = UiImageCatalog.cases.mythic,
            plateTone = "red",
            drops = dropsFor("myth", "Crimson", UiImageCatalog.skins.usp_crimson),
            buys = buys,
        },
    }
end

local function defaultProducts(): { Product }
    return {
        {
            id = "x2_coins",
            title = "x2 Coins",
            itemKey = "x2Coins",
            price = 149,
            kind = "boost",
            featured = false,
        },
        {
            id = "x2_diamonds",
            title = "x2 Diamonds",
            itemKey = "x2Diamonds",
            price = 149,
            kind = "boost",
            featured = false,
        },
        {
            id = "x2_luck",
            title = "x2 Luck",
            itemKey = "x2Luck",
            price = 199,
            kind = "banner",
            featured = true,
        },
        {
            id = "coins_small",
            title = "Coins Pack",
            itemKey = "coinsSmall",
            price = 49,
            kind = "pack",
        },
        {
            id = "coins_medium",
            title = "Coins Pack",
            itemKey = "coinsMedium",
            price = 99,
            kind = "pack",
        },
        {
            id = "coins_big",
            title = "Coins Pack",
            itemKey = "coinsBig",
            price = 199,
            kind = "pack",
            featured = true,
        },
        {
            id = "diamonds_small",
            title = "Diamonds Pack",
            itemKey = "diamondsSmall",
            price = 49,
            kind = "pack",
        },
        {
            id = "diamonds_medium",
            title = "Diamonds Pack",
            itemKey = "diamondsMedium",
            price = 99,
            kind = "pack",
        },
        {
            id = "diamonds_big",
            title = "Diamonds Pack",
            itemKey = "diamondsBig",
            price = 199,
            kind = "pack",
            featured = true,
        },
    }
end

local function itemAspect(key: UiImageCatalog.ShopItemKey): number
    local def = UiImageCatalog.shopItem(key)
    return def.nativeWidth / def.nativeHeight
end

local function itemShineWidth(kind: ShopProductCard.LayoutKind): number
    if kind == "banner" then
        return 0.14
    elseif kind == "boost" then
        return 0.2
    end
    return 0.28
end

local function ShopPanel(props: Props): React.Node
    local offers = props.offers or defaultOffers()
    local products = props.products or defaultProducts()
    local design = useDesign()

    -- Offset row height / pads from ScrollingFrame AbsoluteSize (post-UIScale → design px).
    local offerSizeB, setOfferSize = React.useBinding(UDim2.new(1, 0, 0, 0))
    local boostSizeB, setBoostSize = React.useBinding(UDim2.fromOffset(0, 0))
    local bannerSizeB, setBannerSize = React.useBinding(UDim2.fromOffset(0, 0))
    local packSizeB, setPackSize = React.useBinding(UDim2.fromOffset(0, 0))
    local productPadB, setProductPad = React.useBinding(UDim2.fromOffset(0, 0))
    local boostGapB, setBoostGap = React.useBinding(UDim.new(0, 0))
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
        local offerH = localY * L.offerH
        local padX = localX * L.contentPad
        local padY = localY * L.contentPad
        local gap = localY * L.offerGap
        local productGap = localX * L.productGap
        local boostGap = localX * L.boostGap
        local innerW = math.max(0, localX - 2 * padX)
        local boostW = (innerW - boostGap) * 0.5
        local boostAspect = itemAspect("x2Coins")
        local boostH = boostW / boostAspect
        local bannerAspect = itemAspect("x2Luck")
        local bannerH = innerW / bannerAspect
        local cols = math.max(1, L.productCols)
        local packW = (innerW - (cols - 1) * productGap) / cols
        local packAspect = itemAspect("coinsSmall")
        local packH = packW / packAspect
        if offerH <= 0 or boostW <= 0 or packW <= 0 then
            return
        end
        local key = string.format(
            "%.1f:%.1f:%.1f:%.1f:%.1f:%.1f:%.4f",
            offerH,
            padX,
            gap,
            boostW,
            boostH,
            packH,
            design.scale
        )
        if lastSyncKeyRef.current == key then
            return
        end
        lastSyncKeyRef.current = key
        setOfferSize(UDim2.new(1, 0, 0, offerH))
        setBoostSize(UDim2.fromOffset(boostW, boostH))
        setBannerSize(UDim2.new(1, 0, 0, bannerH))
        setPackSize(UDim2.fromOffset(packW, packH))
        setProductPad(UDim2.fromOffset(productGap, productGap))
        setBoostGap(UDim.new(0, boostGap))
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

    for i, offer in offers do
        listChildren[offer.id] = React.createElement("Frame", {
            Size = offerSizeB,
            BackgroundTransparency = 1,
            LayoutOrder = i,
        }, {
            Card = React.createElement(ShopOfferCard, {
                title = offer.title,
                caseImage = offer.caseImage,
                plateTone = offer.plateTone,
                drops = offer.drops,
                buys = offer.buys,
                onBuy = function(qty: number)
                    if props.onBuy then
                        props.onBuy(offer.id, qty)
                    end
                end,
            }),
        })
    end

    local boosts: { Product } = {}
    local banners: { Product } = {}
    local packs: { Product } = {}
    for _, product in products do
        if product.kind == "boost" then
            table.insert(boosts, product)
        elseif product.kind == "banner" then
            table.insert(banners, product)
        else
            table.insert(packs, product)
        end
    end

    local function makeProductCard(product: Product, order: number, size: UDim2): React.Node
        local def = UiImageCatalog.shopItem(product.itemKey)
        return React.createElement("Frame", {
            Size = size,
            BackgroundTransparency = 1,
            LayoutOrder = order,
        }, {
            Card = React.createElement(ShopProductCard, {
                title = product.title,
                image = def.image,
                aspectRatio = nil,
                shineWidth = itemShineWidth(product.kind),
                price = product.price,
                kind = product.kind,
                featured = product.featured,
                onBuy = function()
                    if props.onBuyProduct then
                        props.onBuyProduct(product.id)
                    end
                end,
            }),
        })
    end

    local boostChildren: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = boostGapB,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, product in boosts do
        -- Binding updates cell size after AbsoluteSize sync.
        boostChildren[product.id] = React.createElement("Frame", {
            Size = boostSizeB,
            BackgroundTransparency = 1,
            LayoutOrder = i,
        }, {
            Card = React.createElement(ShopProductCard, {
                title = product.title,
                image = UiImageCatalog.shopItem(product.itemKey).image,
                aspectRatio = nil,
                shineWidth = itemShineWidth(product.kind),
                price = product.price,
                kind = product.kind,
                featured = product.featured,
                onBuy = function()
                    if props.onBuyProduct then
                        props.onBuyProduct(product.id)
                    end
                end,
            }),
        })
    end

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
                image = UiImageCatalog.shopItem(product.itemKey).image,
                aspectRatio = nil,
                shineWidth = itemShineWidth(product.kind),
                price = product.price,
                kind = product.kind,
                featured = product.featured,
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
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirectionMaxCells = L.productCols,
        }),
    }
    for i, product in packs do
        packChildren[product.id] = makeProductCard(product, i, UDim2.fromScale(1, 1))
    end

    local baseOrder = #offers
    listChildren.Boosts = React.createElement("Frame", {
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = baseOrder + 1,
    }, boostChildren)
    listChildren.Banners = React.createElement("Frame", {
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = baseOrder + 2,
    }, bannerChildren)
    listChildren.Packs = React.createElement("Frame", {
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = baseOrder + 3,
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
                    Image = UiImageCatalog.hudIcon("shop"),
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
