--!strict
-- Center-left stack of MoneyButton pills (DevProduct coin packs).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.Parent.context.HudContext)
local MoneyButton = require(script.Parent.MoneyButton)
local MoneyOfferLogic = require(ReplicatedStorage.shared.util.MoneyOfferLogic)
local theme = require(script.Parent.Parent.theme)

local farmLayout = theme.Layout.farm

local function MoneyOfferButtons(): React.Node
    local ctx = React.useContext(HudContext)
    local packs = MoneyOfferLogic.packs()
    local balance = ctx.hud.coins
    local stackH = farmLayout.moneyOfferBtnH * #packs + farmLayout.moneyOfferGap * (#packs - 1)
    local btnHFrac = farmLayout.moneyOfferBtnH / stackH

    local children: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(farmLayout.moneyOfferGap / stackH, 0),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }

    for index, pack in packs do
        local amount = MoneyOfferLogic.coinsForProductId(pack.productId, balance) or 0
        children[`Offer{index}`] = React.createElement(MoneyButton, {
            amount = amount,
            size = UDim2.fromScale(1, btnHFrac),
            layoutOrder = index,
            shineIntervalSec = 1.85 + index * 0.15,
            disabled = pack.productId <= 0,
            onActivated = function()
                ctx.onMoneyOffer(pack.productId)
            end,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(farmLayout.moneyOfferW, stackH),
        Position = UDim2.fromScale(farmLayout.moneyOfferPadX, farmLayout.moneyOfferCenterY),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 2,
    }, children)
end

return MoneyOfferButtons
