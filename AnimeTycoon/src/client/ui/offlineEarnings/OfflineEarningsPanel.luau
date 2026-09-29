--!strict
-- Offline Earnings panel = StarterGui Window content.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ActionButtons = require(script.Parent.components.ActionButtons)
local MockData = require(script.Parent.MockData)
local OfflineEarningsWindow = require(script.Parent.OfflineEarningsWindow)
local SG = require(script.Parent.layout)
local StrokeText = require(script.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.assets)
local tokens = require(script.Parent.tokens)
local types = require(script.Parent.types)

export type Props = {
    data: types.OfflineEarningsData?,
    onCancel: () -> (),
    onDouble: () -> (),
}

local function OfflineEarningsPanel(props: Props): React.Node
    local data = props.data or MockData.earnings()
    local grad = tokens.moneyGradient

    return React.createElement(OfflineEarningsWindow, {
        title = "Offline Earnings",
    }, {
        Headline = React.createElement(StrokeText, {
            text = data.headline or "While OFFLINE  you earned..",
            strokeThickness = tokens.strokeText,
            size = SG.headline.size,
            position = SG.headline.pos,
            anchorPoint = SG.headline.anchor,
            zIndex = 2,
        }),

        Divider = React.createElement("ImageLabel", {
            Size = SG.divider.size,
            Position = SG.divider.pos,
            AnchorPoint = SG.divider.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = assets.divider,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 2,
        }),

        CurrentLabel = React.createElement(StrokeText, {
            text = "CURRENT",
            color = tokens.muted,
            strokeThickness = tokens.strokeText,
            size = SG.currentLabel.size,
            position = SG.currentLabel.pos,
            anchorPoint = SG.currentLabel.anchor,
            zIndex = 2,
        }),
        CurrentMoney = React.createElement(StrokeText, {
            text = data.currentText,
            color = tokens.muted,
            strokeThickness = tokens.strokeText,
            size = SG.currentMoney.size,
            position = SG.currentMoney.pos,
            anchorPoint = SG.currentMoney.anchor,
            textWrapped = false,
            oversizedFit = true,
            zIndex = 2,
        }),

        DoubleLabel = React.createElement(StrokeText, {
            text = "DOUBLE",
            color = tokens.titleWhite,
            strokeThickness = tokens.strokeText,
            size = SG.doubleLabel.size,
            position = SG.doubleLabel.pos,
            anchorPoint = SG.doubleLabel.anchor,
            zIndex = 2,
            gradient = {
                color = grad.color,
                rotation = grad.rotation,
            },
        }),
        DoubleMoney = React.createElement(StrokeText, {
            text = data.doubleText,
            color = tokens.titleWhite,
            strokeThickness = tokens.strokeText,
            size = SG.doubleMoney.size,
            position = SG.doubleMoney.pos,
            anchorPoint = SG.doubleMoney.anchor,
            textWrapped = false,
            oversizedFit = true,
            zIndex = 2,
            gradient = {
                color = grad.color,
                rotation = grad.rotation,
            },
        }),

        Cancel = React.createElement(ActionButtons.CancelButton, {
            onActivated = props.onCancel,
        }),
        Double = React.createElement(ActionButtons.DoubleButton, {
            price = data.doublePrice,
            onActivated = props.onDouble,
        }),
    })
end

return OfflineEarningsPanel
