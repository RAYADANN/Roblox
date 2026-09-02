--!strict
-- Shop item card from assets/ui/Items — SimPop chrome + single buy (price + Robux).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ButtonImageIds = require(script.Parent.Parent.simpop.ImageIds)
local SimPopChrome = require(script.Parent.Parent.simpop.SimPopChrome)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local playUiClick = require(script.Parent.Parent.util.playUiClick)
local theme = require(script.Parent.Parent.theme)

export type LayoutKind = "pack" | "boost" | "banner"

export type Props = {
    title: string,
    image: string,
    aspectRatio: number?,
    shineWidth: number,
    price: number,
    --- pack = portrait; boost = half-row wide; banner = full-width X2 Luck.
    kind: LayoutKind?,
    featured: boolean?,
    layoutOrder: number?,
    onBuy: (() -> ())?,
}

local P = theme.Layout.shop.product

local function BuyButton(props: {
    price: number,
    featured: boolean?,
    onActivated: (() -> ())?,
}): React.Node
    local tone: ButtonImageIds.SimPopTone = if props.featured then "orange" else "green"
    local chrome = ButtonImageIds.SimPop[tone].horizontal
    local robuxSide, setRobuxSide = React.useBinding(28)

    local function syncRobuxSize(cluster: Frame?)
        if cluster == nil then
            return
        end
        local localH = cluster.AbsoluteSize.Y / P.buyContentScale
        local side = localH * P.buyRobuxH
        if side >= 8 then
            setRobuxSide(math.floor(side + 0.5))
        end
    end

    return React.createElement(SimPopChrome, {
        size = UDim2.fromScale(1, 1),
        background = chrome.background,
        shine = ButtonImageIds.SimPop.shine,
        aspectRatio = nil,
        shineWidth = chrome.shineWidth,
        shineAspect = 92 / 144,
        strokeThickness = theme.Stroke.simPop,
        onActivated = playUiClick.wrapActivated(props.onActivated),
        children = {
            PriceCluster = React.createElement("Frame", {
                Size = UDim2.fromScale(1, P.buyPriceH),
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
                Scale = React.createElement("UIScale", { Scale = P.buyContentScale }),
                Price = React.createElement("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.fromScale(0, 1),
                    Position = UDim2.fromScale(0.5 - P.buyCenterGap * 0.5, 0.5),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Text = tostring(props.price),
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
                    Position = UDim2.fromScale(0.5 + P.buyCenterGap * 0.5, 0.5),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = UiImageCatalog.hudIcon("robux"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 6,
                }),
            }),
        },
    })
end

local function ShopProductCard(props: Props): React.Node
    local kind: LayoutKind = props.kind or "pack"
    local buyW = if kind == "pack"
        then P.packBuyW
        elseif kind == "banner" then P.bannerBuyW
        else P.boostBuyW
    local buyH = if kind == "pack"
        then P.packBuyH
        elseif kind == "banner" then P.bannerBuyH
        else P.boostBuyH
    local buyX = if kind == "pack"
        then P.packBuyX
        elseif kind == "banner" then P.bannerBuyX
        else P.boostBuyX
    local buyY = if kind == "pack"
        then P.packBuyY
        elseif kind == "banner" then P.bannerBuyY
        else P.boostBuyY

    return React.createElement(SimPopChrome, {
        size = UDim2.fromScale(1, 1),
        background = props.image,
        shine = ButtonImageIds.SimPop.shine,
        aspectRatio = props.aspectRatio,
        shineWidth = props.shineWidth,
        shineAspect = nil,
        cornerScale = theme.SimPop.cornerScale,
        strokeThickness = theme.Stroke.slot,
        strokeColor = theme.Colors.black,
        layoutOrder = props.layoutOrder,
        disabled = false,
        children = {
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromScale(P.titleW, P.titleH),
                Position = UDim2.fromScale(P.titlePadX, P.titlePadY),
                BackgroundTransparency = 1,
                Text = string.upper(props.title),
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 4,
            }, {
                Outline = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.title,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                }),
            }),
            Buy = React.createElement("Frame", {
                Size = UDim2.fromScale(buyW, buyH),
                Position = UDim2.fromScale(buyX, buyY),
                AnchorPoint = Vector2.new(1, 1),
                BackgroundTransparency = 1,
                ZIndex = 5,
            }, {
                Btn = React.createElement(BuyButton, {
                    price = props.price,
                    featured = props.featured,
                    onActivated = props.onBuy,
                }),
            }),
        },
    })
end

return ShopProductCard
