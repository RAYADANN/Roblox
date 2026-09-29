--!strict
-- HUD: balance + Index/Shop buttons + inventory + modals.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BalanceChip = require(script.Parent.components.BalanceChip)
local DesignRoot = require(script.Parent.DesignRoot)
local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local HudContext = require(script.Parent.context.HudContext)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local IndexPanel = require(script.Parent.components.IndexPanel)
local InventoryBar = require(script.Parent.components.InventoryBar)
local RebirthPanel = require(script.Parent.components.RebirthPanel)
local ShopPanel = require(script.Parent.components.ShopPanel)
local theme = require(script.Parent.theme)
local useHoverPress = require(script.Parent.hooks.useHoverPress)
local useLayout = require(script.Parent.hooks.useLayout)

local DEMO_OWNED: { [string]: boolean } = {
    cat = true,
    cat_ember = true,
    dog = true,
    owl = true,
    owl_moss = true,
    fish = true,
    fish_frost = true,
    ember_cat = true,
}

local function HudIconButton(props: {
    image: string,
    padRight: number,
    padTop: number,
    sizeScale: number,
    onActivated: () -> (),
}): React.Node
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.08,
        pressScale = 0.92,
    })

    return React.createElement("ImageButton", {
        Size = UDim2.fromScale(props.sizeScale, props.sizeScale),
        Position = UDim2.fromScale(1 - props.padRight, props.padTop),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Image = props.image,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 4,
        [React.Event.Activated] = props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Aspect = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 1,
        }),
        Scale = React.createElement("UIScale", { Scale = hoverScale }),
    })
end

local function App(): React.Node
    local layout = useLayout()
    local ctx = React.useContext(HudContext)
    local hud = ctx.hud
    local inventory = hud.inventory or {}
    local indexOpen, setIndexOpen = React.useState(false)
    local shopOpen, setShopOpen = React.useState(false)
    local rebirthOpen, setRebirthOpen = React.useState(false)

    local handText = if hud.handName
        then `In hand: {hud.handName} — stand on Place Button`
        else "Buy offer → inventory · select item · stand on Button"

    local incomeSum = 0
    for _, slot in hud.slots do
        if slot.occupied then
            incomeSum += slot.incomeRate
        end
    end

    local bank = math.floor((hud.favoriteBank or 0) + 0.5)
    local farm = theme.Layout.farm

    local function openIndex()
        setShopOpen(false)
        setRebirthOpen(false)
        setIndexOpen(true)
    end

    local function openShop()
        setIndexOpen(false)
        setRebirthOpen(false)
        setShopOpen(true)
    end

    local function openRebirth()
        setIndexOpen(false)
        setShopOpen(false)
        setRebirthOpen(true)
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Coins = React.createElement(BalanceChip, { coins = hud.coins }),

        IndexBtn = React.createElement(HudIconButton, {
            image = IconCatalog.Index,
            padRight = farm.indexBtnPadRight,
            padTop = farm.indexBtnPadTop,
            sizeScale = farm.indexBtn,
            onActivated = openIndex,
        }),

        ShopBtn = React.createElement(HudIconButton, {
            image = IconCatalog.Shop,
            padRight = farm.shopBtnPadRight,
            padTop = farm.shopBtnPadTop,
            sizeScale = farm.shopBtn,
            onActivated = openShop,
        }),

        RebirthBtn = React.createElement(HudIconButton, {
            image = IconCatalog.Rebirth,
            padRight = farm.rebirthBtnPadRight,
            padTop = farm.rebirthBtnPadTop,
            sizeScale = farm.rebirthBtn,
            onActivated = openRebirth,
        }),

        Top = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, layout.px(56)),
            Position = UDim2.fromOffset(layout.safeLeft, layout.safeTop),
            BackgroundTransparency = 1,
        }, {
            Bank = React.createElement("TextLabel", {
                Size = UDim2.fromOffset(layout.px(160), layout.px(40)),
                Position = UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1,
                Font = theme.Font.display,
                TextSize = layout.text(16),
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = `Bank ${FormatMoney.comma(bank)}`,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 39, 56),
                    Thickness = 0.1,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
            }),
            Income = React.createElement("TextLabel", {
                Size = UDim2.fromOffset(layout.px(120), layout.px(40)),
                Position = UDim2.fromOffset(layout.px(180), 0),
                BackgroundTransparency = 1,
                Font = theme.Font.display,
                TextSize = layout.text(16),
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = `+{math.floor(incomeSum)}/s`,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 39, 56),
                    Thickness = 0.1,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
            }),
            Hand = React.createElement("TextLabel", {
                Size = UDim2.new(0.5, 0, 0, layout.px(40)),
                Position = UDim2.fromOffset(layout.px(320), 0),
                BackgroundTransparency = 1,
                Font = theme.Font.body,
                TextSize = layout.text(13),
                TextColor3 = theme.Colors.textSub,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = handText,
            }),
        }),

        Inventory = React.createElement(InventoryBar, {
            items = inventory,
            handUid = hud.handUid,
            onSelect = function(uid: string)
                ctx.selectHand(uid)
            end,
        }),

        IndexModal = if indexOpen
            then React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 20,
                Active = true,
            }, {
                Canvas = React.createElement(DesignRoot, {}, {
                    Panel = React.createElement(IndexPanel, {
                        ownedEvolutions = DEMO_OWNED,
                        onClose = function()
                            setIndexOpen(false)
                        end,
                    }),
                }),
            })
            else nil,

        ShopModal = if shopOpen
            then React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 20,
                Active = true,
            }, {
                Canvas = React.createElement(DesignRoot, {}, {
                    Panel = React.createElement(ShopPanel, {
                        progress = {
                            coins = hud.coins,
                            incomePerSec = incomeSum,
                        },
                        onBuyProduct = function(productId: string)
                            print(`[Shop] mock buy {productId}`)
                        end,
                        onClose = function()
                            setShopOpen(false)
                        end,
                    }),
                }),
            })
            else nil,

        RebirthModal = if rebirthOpen
            then React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 20,
                Active = true,
            }, {
                Canvas = React.createElement(DesignRoot, {}, {
                    Panel = React.createElement(RebirthPanel, {
                        coins = hud.coins,
                        rebirths = 0,
                        onClose = function()
                            setRebirthOpen(false)
                        end,
                        onRebirth = function()
                            print("[Rebirth] mock rebirth")
                        end,
                        onSkip = function()
                            print("[Rebirth] mock skip")
                            setRebirthOpen(false)
                        end,
                    }),
                }),
            })
            else nil,
    })
end

return App
