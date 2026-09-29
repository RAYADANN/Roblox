--!strict
-- Money: иконка + зелёный текст со stroke (StarterGui.HUD.Money).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)

export type Props = {
    text: string,
}

local function MoneyDisplay(props: Props): React.Node
    local M = SG.money

    return React.createElement("Frame", {
        Size = M.size,
        Position = M.pos,
        AnchorPoint = M.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, {
        Icon = React.createElement("ImageLabel", {
            Size = M.icon.size,
            Position = M.icon.pos,
            AnchorPoint = M.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = assets.moneyIcon,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 2,
        }),
        Amount = React.createElement("TextLabel", {
            Size = M.amount.size,
            Position = M.amount.pos,
            AnchorPoint = M.amount.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = props.text,
            TextScaled = true,
            Font = tokens.font,
            TextColor3 = tokens.titleWhite,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 3,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = tokens.moneyStroke,
                Thickness = tokens.strokeMoney,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
            Gradient = React.createElement("UIGradient", {
                Color = tokens.moneyGradient,
                Rotation = 90,
            }),
        }),
    })
end

return MoneyDisplay
