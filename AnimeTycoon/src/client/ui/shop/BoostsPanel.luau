--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BoostCard = require(script.Parent.components.BoostCard)
local ShopWindow = require(script.Parent.ShopWindow)
local layout = require(script.Parent.layout)
local types = require(script.Parent.types)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    offers: { types.BoostOffer },
    onBuy: (productId: string) -> (),
    onGift: ((productId: string) -> ())?,
    onClose: () -> (),
}

local function BoostsPanel(props: Props): React.Node
    local ui = useLayout()
    local rowH = ui.px(layout.luckRowH)
    local gap = ui.gap(layout.sectionGap)

    local row1: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, gap),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    local row2: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, gap),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }

    for i, offer in props.offers do
        local target = if i <= 2 then row1 else row2
        local order = if i <= 2 then i else i - 2
        target["B" .. offer.id] = React.createElement("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundTransparency = 1,
            LayoutOrder = order,
        }, {
            Aspect = React.createElement("UIAspectRatioConstraint", {
                AspectRatio = layout.luckAspect,
                DominantAxis = Enum.DominantAxis.Height,
            }),
            Card = React.createElement(BoostCard, {
                offer = offer,
                onBuy = props.onBuy,
                onGift = props.onGift,
                size = UDim2.fromScale(1, 1),
            }),
        })
    end

    return React.createElement(ShopWindow, {
        title = "Boosts",
        onClose = props.onClose,
    }, {
        List = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, gap),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            Row1 = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, rowH),
                BackgroundTransparency = 1,
                LayoutOrder = 1,
            }, row1),
            Row2 = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, rowH),
                BackgroundTransparency = 1,
                LayoutOrder = 2,
            }, row2),
        }),
    })
end

return BoostsPanel
