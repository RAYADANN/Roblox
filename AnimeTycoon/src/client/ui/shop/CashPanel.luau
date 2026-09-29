--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local CashCard = require(script.Parent.components.CashCard)
local ShopWindow = require(script.Parent.ShopWindow)
local layout = require(script.Parent.layout)
local types = require(script.Parent.types)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    offers: { types.CashOffer },
    onBuy: (productId: string) -> (),
    onGift: ((productId: string) -> ())?,
    onClose: () -> (),
}

local function CashPanel(props: Props): React.Node
    local ui = useLayout()
    local rowH = ui.px(layout.moneyRowH)
    local gap = ui.gap(layout.sectionGap)

    local items: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, gap),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Wraps = true,
        }),
    }
    for i, offer in props.offers do
        items["C" .. offer.id] = React.createElement("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundTransparency = 1,
            LayoutOrder = i,
        }, {
            Aspect = React.createElement("UIAspectRatioConstraint", {
                AspectRatio = layout.moneyAspect,
                DominantAxis = Enum.DominantAxis.Height,
            }),
            SizeConstraint = React.createElement("UISizeConstraint", {
                MaxSize = Vector2.new(math.huge, rowH),
            }),
            Card = React.createElement(CashCard, {
                offer = offer,
                onBuy = props.onBuy,
                onGift = props.onGift,
                size = UDim2.fromScale(1, 1),
            }),
        })
    end

    return React.createElement(ShopWindow, {
        title = "CASH",
        onClose = props.onClose,
    }, {
        Row = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, rowH),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
        }, items),
    })
end

return CashPanel
