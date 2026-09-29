--!strict
-- HUD: money bar + left icon dock (Shop / Rebirth / Gift / Index).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudIcon = require(script.Parent.components.HudIcon)
local MockData = require(script.Parent.MockData)
local MoneyDisplay = require(script.Parent.components.MoneyDisplay)
local SG = require(script.Parent.layout)
local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

export type Props = {
    data: types.HudData?,
    onShop: (() -> ())?,
    onIndex: (() -> ())?,
    onGift: (() -> ())?,
    onRebirth: (() -> ())?,
}

local function HudPanel(props: Props): React.Node
    local data = props.data or MockData.hud()
    local I = SG.icons

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Money = React.createElement(MoneyDisplay, {
            text = data.moneyText,
        }),
        Icons = React.createElement("Frame", {
            Size = I.size,
            Position = I.pos,
            AnchorPoint = I.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            Shop = React.createElement(HudIcon, {
                image = assets.shop,
                label = "SHOP",
                position = I.shop.pos,
                onActivated = props.onShop,
            }),
            Rebirth = React.createElement(HudIcon, {
                image = assets.rebirth,
                label = "REBIRTH",
                position = I.rebirth.pos,
                onActivated = props.onRebirth,
            }),
            Gift = React.createElement(HudIcon, {
                image = assets.gift,
                label = "REWARDS",
                position = I.gift.pos,
                onActivated = props.onGift,
            }),
            Index = React.createElement(HudIcon, {
                image = assets.index,
                label = "INDEX",
                position = I.index.pos,
                onActivated = props.onIndex,
            }),
        }),
    })
end

return HudPanel
