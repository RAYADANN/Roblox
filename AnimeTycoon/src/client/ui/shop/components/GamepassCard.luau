--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local PromoBadge = require(script.Parent.PromoBadge)
local RobuxButton = require(script.Parent.RobuxButton)
local StrokeText = require(script.Parent.StrokeText)
local StudPanel = require(script.Parent.StudPanel)
local theme = require(script.Parent.Parent.Parent.theme)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)
local useLayout = require(script.Parent.Parent.Parent.hooks.useLayout)

export type Props = {
    offer: types.GamepassOffer,
    onBuy: (productId: string) -> (),
    layoutOrder: number?,
}

local function GamepassCard(props: Props): React.Node
    local layout = useLayout()
    local offer = props.offer
    local h = layout.px(130)

    local perkChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, layout.gap(4)),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, perk in offer.perks or {} do
        perkChildren["P" .. i] = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, layout.px(20)),
            BackgroundTransparency = 1,
            LayoutOrder = i,
        }, {
            Dot = React.createElement("Frame", {
                Size = UDim2.fromOffset(layout.px(14), layout.px(14)),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = theme.Colors.gold,
                BorderSizePixel = 0,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = theme.Colors.outlineDark,
                    Thickness = 1.5,
                }),
            }),
            Label = React.createElement(StrokeText, {
                text = perk.text,
                textSize = 13,
                size = UDim2.new(1, -layout.px(22), 1, 0),
                position = UDim2.fromOffset(layout.px(20), 0),
                textXAlignment = Enum.TextXAlignment.Left,
            }),
        })
    end

    return React.createElement(StudPanel, {
        size = UDim2.new(1, 0, 0, h),
        color = offer.accent or theme.Colors.gold,
        layoutOrder = props.layoutOrder,
    }, {
        Padding = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, layout.gap(10)),
            PaddingBottom = UDim.new(0, layout.gap(10)),
            PaddingLeft = UDim.new(0, layout.gap(12)),
            PaddingRight = UDim.new(0, layout.gap(12)),
        }),
        Icon = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(72), layout.px(72)),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = theme.Colors.white,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.outlineDark,
                Thickness = tokens.strokeCard,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
        }),
        Info = React.createElement("Frame", {
            Size = UDim2.new(1, -layout.px(200), 1, 0),
            Position = UDim2.fromOffset(layout.px(86), 0),
            BackgroundTransparency = 1,
        }, {
            Title = React.createElement(StrokeText, {
                text = offer.title,
                textSize = 22,
                size = UDim2.new(1, 0, 0, layout.px(28)),
                textXAlignment = Enum.TextXAlignment.Left,
            }),
            Perks = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, -layout.px(32)),
                Position = UDim2.fromOffset(0, layout.px(30)),
                BackgroundTransparency = 1,
            }, perkChildren),
        }),
        Badge = if offer.badge
            then React.createElement(PromoBadge, {
                text = offer.badge,
            })
            else nil,
        Buy = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(120), layout.px(56)),
            Position = UDim2.new(1, 0, 1, 0),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
        }, {
            Btn = React.createElement(RobuxButton, {
                price = offer.offer.price,
                originalPrice = offer.offer.originalPrice,
                onActivated = function()
                    props.onBuy(offer.offer.productId)
                end,
            }),
        }),
    })
end

return GamepassCard
