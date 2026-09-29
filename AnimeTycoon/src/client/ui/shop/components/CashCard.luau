--!strict
-- CashCard = MoneyItem из StarterGui (внутренние доли 1:1).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local GiftButton = require(script.Parent.GiftButton)
local RobuxButton = require(script.Parent.RobuxButton)
local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)

export type Props = {
    offer: types.CashOffer,
    onBuy: (productId: string) -> (),
    onGift: ((productId: string) -> ())?,
    layoutOrder: number?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
}

local function CashCard(props: Props): React.Node
    local offer = props.offer
    local M = SG.money

    return React.createElement("Frame", {
        Size = props.size or M.size,
        Position = props.position,
        AnchorPoint = props.anchorPoint or M.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
        Bg = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = offer.image or assets.moneyBg,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = tokens.titleShadow,
                Thickness = tokens.strokeCard,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
        }),
        Icon = React.createElement("ImageLabel", {
            Size = M.icon.size,
            Position = M.icon.pos,
            AnchorPoint = M.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = offer.iconImage or assets.moneyIcon,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 2,
        }),
        Value = React.createElement(StrokeText, {
            text = offer.valueText,
            color = tokens.valueGreen,
            strokeThickness = tokens.strokeTitle,
            size = M.value.size,
            position = M.value.pos,
            anchorPoint = M.value.anchor,
            zIndex = 3,
        }),
        Buy = React.createElement(RobuxButton, {
            price = offer.offer.price,
            originalPrice = offer.offer.originalPrice,
            variant = "money",
            size = M.buy.size,
            position = M.buy.pos,
            anchorPoint = M.buy.anchor,
            onActivated = function()
                props.onBuy(offer.offer.productId)
            end,
        }),
        Gift = React.createElement(GiftButton, {
            size = M.gift.size,
            position = M.gift.pos,
            anchorPoint = M.gift.anchor,
            onActivated = if props.onGift
                then function()
                    props.onGift(offer.offer.productId)
                end
                else nil,
        }),
    })
end

return CashCard
