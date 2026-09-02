--!strict
-- Shop offer row: long SimPop plate + case art + drop previews + qty buy buttons.
-- Proportions: theme.Layout.shop.offer (+ offerH on the list row).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ButtonImageIds = require(script.Parent.Parent.simpop.ImageIds)
local RarityLogic = require(ReplicatedStorage.shared.util.RarityLogic)
local SimPopBlock = require(script.Parent.Parent.simpop.block.SimPopBlock)
local SimPopChrome = require(script.Parent.Parent.simpop.SimPopChrome)
local SimPopLongBlock = require(script.Parent.Parent.simpop.block.SimPopLongBlock)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local playUiClick = require(script.Parent.Parent.util.playUiClick)
local theme = require(script.Parent.Parent.theme)

export type DropPreview = {
    id: string,
    name: string,
    chanceLabel: string,
    rarity: string,
    image: string?,
}

export type BuyOption = {
    qty: number,
    price: number,
    --- Highlight pack (mockup: 5x is gold).
    featured: boolean?,
}

export type Props = {
    title: string,
    caseImage: string,
    --- Long plate chrome behind the offer row (shop/case colors from assets).
    plateTone: SimPopLongBlock.LongTone?,
    drops: { DropPreview },
    buys: { BuyOption },
    layoutOrder: number?,
    onBuy: ((qty: number) -> ())?,
}

local O = theme.Layout.shop.offer

local function DropSlot(props: {
    drop: DropPreview,
    layoutOrder: number,
}): React.Node
    local drop = props.drop
    local tone = RarityLogic.blockTone(drop.rarity)
    local hasImage = typeof(drop.image) == "string"
        and drop.image ~= ""
        and drop.image ~= "rbxassetid://0"

    return React.createElement("Frame", {
        Size = UDim2.fromScale(0.22, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
    }, {
        Card = React.createElement(SimPopBlock, {
            tone = tone,
            size = UDim2.fromScale(1, O.dropCardH),
            preserveAspect = false,
            disabled = true,
            children = {
                Chance = React.createElement("TextLabel", {
                    Size = UDim2.fromScale(0.9, 0.22),
                    Position = UDim2.fromScale(0.5, 0.06),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = drop.chanceLabel,
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 3,
                }, {
                    Outline = React.createElement("UIStroke", {
                        Color = theme.Colors.black,
                        Thickness = theme.Stroke.text,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    }),
                }),
                Art = if hasImage
                    then React.createElement("ImageLabel", {
                        Size = UDim2.fromScale(0.78, 0.55),
                        Position = UDim2.fromScale(0.5, 0.55),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = drop.image :: string,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 2,
                    })
                    else nil,
            },
        }),
        Name = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, O.dropNameH),
            Position = UDim2.fromScale(0.5, 0.98),
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundTransparency = 1,
            Text = string.upper(drop.name),
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            ZIndex = 2,
        }, {
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        }),
    })
end

local function BuyButton(props: {
    option: BuyOption,
    layoutOrder: number,
    onBuy: ((qty: number) -> ())?,
}): React.Node
    local option = props.option
    local tone: ButtonImageIds.SimPopTone = if option.featured then "orange" else "blue"
    local chrome = ButtonImageIds.SimPop[tone].horizontal

    local robuxSide, setRobuxSide = React.useBinding(32)
    local function syncRobuxSize(cluster: Frame?)
        if cluster == nil then
            return
        end
        -- AbsoluteSize is post-UIScale; offset size uses local space before child UIScale.
        local localH = cluster.AbsoluteSize.Y / O.buyContentScale
        local side = localH * O.buyRobuxH
        if side >= 8 then
            setRobuxSide(math.floor(side + 0.5))
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(O.buyW, 1),
        BackgroundTransparency = 1,
        LayoutOrder = props.layoutOrder,
    }, {
        Btn = React.createElement(SimPopChrome, {
            size = UDim2.fromScale(1, 1),
            background = chrome.background,
            shine = ButtonImageIds.SimPop.shine,
            aspectRatio = nil,
            shineWidth = chrome.shineWidth,
            shineAspect = 92 / 144,
            strokeThickness = theme.Stroke.simPop,
            onActivated = playUiClick.wrapActivated(function()
                if props.onBuy then
                    props.onBuy(option.qty)
                end
            end),
            children = {
                -- Qty: Scale of button; UIScale grows from top-right corner.
                Qty = React.createElement("TextLabel", {
                    Size = UDim2.fromScale(O.buyQtyW, O.buyQtyH),
                    Position = UDim2.fromScale(O.buyQtyX, O.buyQtyY),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
                    Text = `{option.qty}X`,
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    ZIndex = 3,
                }, {
                    Scale = React.createElement("UIScale", { Scale = O.buyQtyScale }),
                    Outline = React.createElement("UIStroke", {
                        Color = theme.Colors.black,
                        Thickness = theme.Stroke.text,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    }),
                }),
                -- Price + Robux: center pivot; Robux size in Offset px from cluster height.
                PriceCluster = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, O.buyPriceH),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    ZIndex = 5,
                    ref = function(rbx: Frame?)
                        syncRobuxSize(rbx)
                    end,
                    [React.Change.AbsoluteSize] = function(rbx: Frame)
                        syncRobuxSize(rbx)
                    end,
                }, {
                    Scale = React.createElement("UIScale", { Scale = O.buyContentScale }),
                    Price = React.createElement("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.fromScale(0, 1),
                        Position = UDim2.fromScale(0.5 - O.buyCenterGap * 0.5, 0.5),
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Text = tostring(option.price),
                        Font = theme.Font.display,
                        TextScaled = true,
                        TextColor3 = theme.Colors.white,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 6,
                    }, {
                        Outline = React.createElement("UIStroke", {
                            Color = theme.Colors.black,
                            Thickness = theme.Stroke.text,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        }),
                    }),
                    Robux = React.createElement("ImageLabel", {
                        Size = robuxSide:map(function(side: number)
                            return UDim2.fromOffset(side, side)
                        end),
                        Position = UDim2.fromScale(0.5 + O.buyCenterGap * 0.5, 0.5),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Image = UiImageCatalog.hudIcon("robux"),
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 6,
                    }),
                }),
            },
        }),
    })
end

local function ShopOfferCard(props: Props): React.Node
    local dropChildren: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(O.dropGap, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, drop in props.drops do
        dropChildren["D" .. drop.id] = React.createElement(DropSlot, {
            drop = drop,
            layoutOrder = i,
        })
    end

    local buyChildren: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(O.buyGap, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, option in props.buys do
        buyChildren["B" .. tostring(option.qty)] = React.createElement(BuyButton, {
            option = option,
            layoutOrder = i,
            onBuy = props.onBuy,
        })
    end

    local caseY, setCaseY = React.useBinding(O.caseY)
    React.useEffect(function()
        local t0 = os.clock()
        local amp = O.caseBobAmp
        local hz = O.caseBobHz
        local conn = RunService.RenderStepped:Connect(function()
            local phase = (os.clock() - t0) * hz * math.pi * 2
            setCaseY(O.caseY + math.sin(phase) * amp)
        end)
        return function()
            conn:Disconnect()
        end
    end, { O.caseY, O.caseBobAmp, O.caseBobHz })

    return React.createElement(SimPopLongBlock, {
        tone = props.plateTone or "purple",
        size = UDim2.fromScale(1, 1),
        preserveAspect = false,
        layoutOrder = props.layoutOrder,
        disabled = false,
        children = {
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromScale(O.titleW, O.titleH),
                Position = UDim2.fromScale(O.titlePadX, O.titlePadY),
                BackgroundTransparency = 1,
                Text = string.upper(props.title),
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 3,
            }, {
                Outline = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.title,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                }),
            }),
            CaseArt = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(O.caseW, O.caseH),
                Position = caseY:map(function(y: number)
                    return UDim2.fromScale(O.caseX, y)
                end),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Image = props.caseImage,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2,
            }),
            Drops = React.createElement("Frame", {
                Size = UDim2.fromScale(O.dropsW, O.dropsH),
                Position = UDim2.fromScale(O.dropsX, O.dropsY),
                BackgroundTransparency = 1,
                ZIndex = 2,
            }, dropChildren),
            Buys = React.createElement("Frame", {
                Size = UDim2.fromScale(O.buysW, O.buysH),
                Position = UDim2.fromScale(O.buysX, O.buysY),
                AnchorPoint = Vector2.new(1, 1),
                BackgroundTransparency = 1,
                ZIndex = 3,
            }, buyChildren),
        },
    })
end

return ShopOfferCard
