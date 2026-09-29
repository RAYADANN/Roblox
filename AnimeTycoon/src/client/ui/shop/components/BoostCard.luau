--!strict
-- BoostCard = YellowLuck / PinkLuck из StarterGui (внутренние доли 1:1).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local GiftButton = require(script.Parent.GiftButton)
local RobuxButton = require(script.Parent.RobuxButton)
local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.StrokeText)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)

export type Props = {
    offer: types.BoostOffer,
    onBuy: (productId: string) -> (),
    onGift: ((productId: string) -> ())?,
    layoutOrder: number?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
}

local function BoostCard(props: Props): React.Node
    local offer = props.offer
    local L = SG.luck
    local buyVariant = offer.buyVariant or "yellow"

    return React.createElement("Frame", {
        Size = props.size or L.size,
        Position = props.position,
        AnchorPoint = props.anchorPoint or L.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
        Bg = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = offer.image or "",
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
            Size = L.icon.size,
            Position = L.icon.pos,
            AnchorPoint = L.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = offer.iconImage or "",
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 2,
        }),
        Mult = if offer.multiplierText
            then React.createElement(StrokeText, {
                text = offer.multiplierText,
                strokeThickness = tokens.strokeText,
                size = L.mult.size,
                position = L.mult.pos,
                anchorPoint = L.mult.anchor,
                zIndex = 3,
            })
            else nil,
        Title = React.createElement(StrokeText, {
            text = offer.title,
            strokeThickness = tokens.strokeText,
            size = L.title.size,
            position = L.title.pos,
            anchorPoint = L.title.anchor,
            zIndex = 3,
        }),
        Desc = React.createElement(StrokeText, {
            text = offer.description,
            strokeThickness = tokens.strokeText,
            size = L.desc.size,
            position = L.desc.pos,
            anchorPoint = L.desc.anchor,
            zIndex = 3,
        }),
        Buy = React.createElement(RobuxButton, {
            price = offer.offer.price,
            originalPrice = offer.offer.originalPrice,
            variant = buyVariant,
            size = L.buy.size,
            position = L.buy.pos,
            anchorPoint = L.buy.anchor,
            onActivated = function()
                props.onBuy(offer.offer.productId)
            end,
        }),
        Gift = React.createElement(GiftButton, {
            size = L.gift.size,
            position = L.gift.pos,
            anchorPoint = L.gift.anchor,
            onActivated = if props.onGift
                then function()
                    props.onGift(offer.offer.productId)
                end
                else nil,
        }),
    })
end

return BoostCard
