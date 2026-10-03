--!strict
-- HUD: left icon dock (Shop / Rebirth / Gift / Index). Money — в HudShell выше FX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudIcon = require(script.Parent.components.HudIcon)
local SG = require(script.Parent.layout)
local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

export type Props = {
    data: types.HudData?,
    onShop: (() -> ())?,
    onIndex: (() -> ())?,
    onGift: (() -> ())?,
    onRebirth: (() -> ())?,
    onUpgrades: (() -> ())?,
    --- Pulse REWARDS icon when a timed reward can be claimed.
    giftAttention: boolean?,
}

local function HudPanel(props: Props): React.Node
    local I = SG.icons

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
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
                image = assets.upgrades,
                label = "UPGRADES",
                position = I.rebirth.pos,
                onActivated = props.onUpgrades or props.onRebirth,
            }),
            Gift = React.createElement(HudIcon, {
                image = assets.gift,
                label = "REWARDS",
                position = I.gift.pos,
                onActivated = props.onGift,
                attention = props.giftAttention == true,
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
