--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local PromoBadge = require(script.Parent.components.PromoBadge)
local RobuxButton = require(script.Parent.components.RobuxButton)
local ShopWindow = require(script.Parent.ShopWindow)
local StrokeText = require(script.Parent.components.StrokeText)
local assets = require(script.Parent.assets)
local tokens = require(script.Parent.tokens)
local types = require(script.Parent.types)

export type Props = {
    offers: { types.GamepassOffer },
    onBuy: (productId: string) -> (),
    onClose: () -> (),
}

local function GamepassRow(props: {
    offer: types.GamepassOffer,
    onBuy: (productId: string) -> (),
    layoutOrder: number,
}): React.Node
    local offer = props.offer
    local perks: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, perk in offer.perks or {} do
        perks["P" .. i] = React.createElement(StrokeText, {
            text = perk.text,
            strokeThickness = tokens.strokeText,
            size = UDim2.new(1, 0, 0, 22),
            textXAlignment = Enum.TextXAlignment.Left,
            layoutOrder = i,
            textScaled = true,
        })
    end

    return React.createElement("ImageLabel", {
        Size = UDim2.new(1, 0, 0, 120),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = assets.luckYellowBg,
        ImageColor3 = offer.accent or Color3.fromRGB(255, 170, 40),
        ScaleType = Enum.ScaleType.Stretch,
        LayoutOrder = props.layoutOrder,
    }, {
        Stroke = React.createElement("UIStroke", {
            Color = tokens.titleShadow,
            Thickness = tokens.strokeCard,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
        Title = React.createElement(StrokeText, {
            text = offer.title,
            size = UDim2.new(0.5, 0, 0, 36),
            position = UDim2.fromOffset(16, 8),
            textXAlignment = Enum.TextXAlignment.Left,
        }),
        Perks = React.createElement("Frame", {
            Size = UDim2.new(0.55, 0, 0, 70),
            Position = UDim2.fromOffset(16, 44),
            BackgroundTransparency = 1,
        }, perks),
        Badge = if offer.badge
            then React.createElement(PromoBadge, { text = offer.badge })
            else nil,
        Buy = React.createElement(RobuxButton, {
            price = offer.offer.price,
            originalPrice = offer.offer.originalPrice,
            variant = "default",
            size = UDim2.fromOffset(130, 48),
            position = UDim2.new(1, -16, 1, -12),
            anchorPoint = Vector2.new(1, 1),
            onActivated = function()
                props.onBuy(offer.offer.productId)
            end,
        }),
    })
end

local function GamepassesPanel(props: Props): React.Node
    local rows: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Pad = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
        }),
    }
    for i, offer in props.offers do
        rows["G" .. offer.id] = React.createElement(GamepassRow, {
            offer = offer,
            onBuy = props.onBuy,
            layoutOrder = i,
        })
    end

    return React.createElement(ShopWindow, {
        title = "GAMEPASSES",
        onClose = props.onClose,
    }, {
        List = React.createElement("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 6,
            CanvasSize = UDim2.fromOffset(0, #props.offers * 140),
        }, rows),
    })
end

return GamepassesPanel
