--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DropCard = require(script.Parent.DropCard)
local PromoBadge = require(script.Parent.PromoBadge)
local RobuxButton = require(script.Parent.RobuxButton)
local StrokeText = require(script.Parent.StrokeText)
local StudPanel = require(script.Parent.StudPanel)
local theme = require(script.Parent.Parent.Parent.theme)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)
local useLayout = require(script.Parent.Parent.Parent.hooks.useLayout)

export type Props = {
    pack: types.PackOffer,
    onBuy: (productId: string) -> (),
    layoutOrder: number?,
}

local function PackRow(props: Props): React.Node
    local layout = useLayout()
    local pack = props.pack
    local rowH = layout.px(tokens.packRowH)

    local dropChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, layout.gap(6)),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    }
    for i, drop in pack.drops do
        dropChildren["D" .. drop.id] = React.createElement(DropCard, {
            drop = drop,
            layoutOrder = i,
        })
    end

    local buyChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, layout.gap(10)),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        }),
    }
    for i, buy in pack.buys do
        buyChildren["B" .. buy.productId] = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(120), layout.px(64)),
            BackgroundTransparency = 1,
            LayoutOrder = i,
        }, {
            Btn = React.createElement(RobuxButton, {
                price = buy.price,
                originalPrice = buy.originalPrice,
                highlight = buy.originalPrice ~= nil,
                onActivated = function()
                    props.onBuy(buy.productId)
                end,
            }),
            Qty = React.createElement(StrokeText, {
                text = buy.label or "",
                textSize = 12,
                size = UDim2.new(1, 0, 0, layout.px(16)),
                position = UDim2.new(0, 0, 1, 0),
                anchorPoint = Vector2.new(0, 1),
            }),
        })
    end

    return React.createElement(StudPanel, {
        size = UDim2.new(1, 0, 0, rowH),
        color = Color3.fromRGB(180, 155, 115),
        layoutOrder = props.layoutOrder,
        clipsDescendants = true,
    }, {
        Padding = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, layout.gap(10)),
            PaddingBottom = UDim.new(0, layout.gap(10)),
            PaddingLeft = UDim.new(0, layout.gap(10)),
            PaddingRight = UDim.new(0, layout.gap(10)),
        }),
        Hero = React.createElement("Frame", {
            Size = UDim2.new(0.22, 0, 1, 0),
            BackgroundColor3 = theme.Colors.bg3,
            BorderSizePixel = 0,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.outlineDark,
                Thickness = tokens.strokeCard,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
            Art = React.createElement("Frame", {
                Size = UDim2.fromScale(0.7, 0.55),
                Position = UDim2.fromScale(0.5, 0.35),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = theme.Colors.gold,
                BorderSizePixel = 0,
            }),
            Sub = React.createElement(StrokeText, {
                text = pack.subtitle or "",
                textSize = 12,
                color = Color3.fromRGB(180, 100, 255),
                size = UDim2.new(1, -8, 0, layout.px(16)),
                position = UDim2.new(0.5, 0, 1, -layout.px(36)),
                anchorPoint = Vector2.new(0.5, 1),
            }),
            Name = React.createElement(StrokeText, {
                text = pack.title,
                textSize = 14,
                color = Color3.fromRGB(255, 220, 40),
                size = UDim2.new(1, -8, 0, layout.px(18)),
                position = UDim2.new(0.5, 0, 1, -layout.gap(6)),
                anchorPoint = Vector2.new(0.5, 1),
            }),
            Badge = if pack.badge
                then React.createElement(PromoBadge, {
                    text = pack.badge,
                    position = UDim2.fromOffset(layout.gap(4), layout.gap(4)),
                    anchorPoint = Vector2.new(0, 0),
                    rotation = -6,
                })
                else nil,
        }),
        Right = React.createElement("Frame", {
            Size = UDim2.new(0.76, 0, 1, 0),
            Position = UDim2.fromScale(0.24, 0),
            BackgroundTransparency = 1,
        }, {
            Hint = React.createElement(StrokeText, {
                text = "All Mutations Possible",
                textSize = 11,
                color = theme.Colors.textSub,
                size = UDim2.new(1, 0, 0, layout.px(16)),
                textXAlignment = Enum.TextXAlignment.Left,
            }),
            Drops = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, layout.px(110)),
                Position = UDim2.fromOffset(0, layout.px(20)),
                BackgroundTransparency = 1,
            }, dropChildren),
            Buys = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, layout.px(64)),
                Position = UDim2.new(0, 0, 1, 0),
                AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 1,
            }, buyChildren),
        }),
    })
end

return PackRow
