--!strict
-- Money: иконка + зелёный счётчик (spring) + pop при прилёте монет.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Formatters = require(script.Parent.Parent.Parent.util.Formatters)
local HudMoneyAnchor = require(script.Parent.Parent.Parent.fx.HudMoneyAnchor)
local MotionPresets = require(script.Parent.Parent.Parent.motion.MotionPresets)
local SG = require(script.Parent.Parent.layout)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local useFlipperSpring = require(script.Parent.Parent.Parent.hooks.useFlipperSpring)

export type Props = {
    amount: number,
}

local function MoneyDisplay(props: Props): React.Node
    local M = SG.money
    local amount = props.amount or 0
    local display = useFlipperSpring(amount, MotionPresets.SPRING_NUMBER)
    local popGoal, setPopGoal = React.useState(1)
    local popScale = useFlipperSpring(popGoal, MotionPresets.SPRING_BOUNCY)

    React.useEffect(function()
        HudMoneyAnchor.setPulseHandler(function()
            setPopGoal(MotionPresets.POP_PEAK)
            task.defer(function()
                setPopGoal(1)
            end)
        end)
        return function()
            HudMoneyAnchor.setPulseHandler(nil)
            HudMoneyAnchor.bind(nil)
        end
    end, {})

    return React.createElement("Frame", {
        Size = M.size,
        Position = M.pos,
        AnchorPoint = M.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        -- Above FxHost (60): coins fly under the balance chip
        ZIndex = 100,
        ref = function(rbx: Frame?)
            HudMoneyAnchor.bind(rbx)
        end,
        [React.Change.AbsolutePosition] = function(rbx: Frame)
            HudMoneyAnchor.bind(rbx)
        end,
        [React.Change.AbsoluteSize] = function(rbx: Frame)
            HudMoneyAnchor.bind(rbx)
        end,
    }, {
        PopScale = React.createElement("UIScale", {
            Scale = popScale,
        }),
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
            Text = "$" .. Formatters.shortNumber(math.max(0, display or 0)),
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
                LineJoinMode = Enum.LineJoinMode.Bevel,
            }),
            Gradient = React.createElement("UIGradient", {
                Color = tokens.moneyGradient,
                Rotation = 90,
            }),
        }),
    })
end

return MoneyDisplay
