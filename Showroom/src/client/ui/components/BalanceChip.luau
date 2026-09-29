--!strict
-- Tycoon FarmHud BalanceChip: bottom-left money bar + coin icon + $amount.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

local STROKE_TEAL = Color3.fromRGB(0, 39, 56)
local farmLayout = theme.Layout.farm
local BALANCE_POP_PEAK = 1.08

local function textStroke(): React.Node
    return React.createElement("UIStroke", {
        Color = STROKE_TEAL,
        Thickness = 0.1,
        Transparency = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        LineJoinMode = Enum.LineJoinMode.Round,
        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
    })
end

export type Props = {
    coins: number,
}

local function BalanceChip(props: Props): React.Node
    local coins = props.coins
    local display = useFlipperSpring(coins, MotionPresets.SPRING_NUMBER)
    local popScale, setPopScale = React.useState(1)
    local prevCoins = React.useRef(coins)
    local popMotorRef = React.useRef(nil :: Flipper.SingleMotor?)

    React.useEffect(function()
        local motor = Flipper.SingleMotor.new(1, false)
        popMotorRef.current = motor
        local conn = motor:onStep(function(v: number)
            setPopScale(v)
        end)
        motor:start()
        return function()
            conn:disconnect()
            motor:destroy()
            popMotorRef.current = nil
        end
    end, {})

    React.useEffect(function()
        local previous = prevCoins.current
        prevCoins.current = coins
        if coins <= previous then
            return
        end
        local motor = popMotorRef.current
        if motor == nil then
            return
        end
        motor:setGoal(Flipper.Spring.new(BALANCE_POP_PEAK, {
            frequency = MotionPresets.SPRING_BOUNCY.frequency,
            dampingRatio = MotionPresets.SPRING_BOUNCY.dampingRatio,
        }))
        task.delay(0.08, function()
            local live = popMotorRef.current
            if live == nil then
                return
            end
            live:setGoal(Flipper.Spring.new(1, {
                frequency = MotionPresets.SPRING_SNAPPY.frequency,
                dampingRatio = MotionPresets.SPRING_SNAPPY.dampingRatio,
            }))
        end)
    end, { coins })

    local barPxW = farmLayout.balanceBarPxW
    local barPxH = farmLayout.balanceBarPxH
    local iconLeftFrac = farmLayout.balanceIconLeftPx / barPxW
    local iconSizeWFrac = farmLayout.balanceIconSizePx / barPxW
    local iconSizeHFrac = farmLayout.balanceIconSizePx / barPxH
    local textLeftPx = farmLayout.balanceIconLeftPx
        + farmLayout.balanceIconSizePx / 1.1
        + farmLayout.balanceIconTextGapPx
    local textLeftFrac = textLeftPx / barPxW
    local textWidthFrac = 1 - textLeftFrac - (farmLayout.balanceTextRightPx / barPxW)
    local moneyBarBg = IconCatalog.resolveImage(IconCatalog.MoneyBarBg, "BalanceBarBg")
    local moneyIcon = IconCatalog.resolveImage(IconCatalog.Money, "Money")
    local shown = math.floor(display + 0.5)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(farmLayout.balanceW, farmLayout.balanceH),
        Position = UDim2.fromScale(farmLayout.balancePadX, 1 - farmLayout.balancePadBottom),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, {
        Scale = React.createElement("UIScale", { Scale = popScale }),
        Background = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1.1, 1.1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = moneyBarBg,
            ImageColor3 = Color3.new(1, 1, 1),
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
        }),
        Icon = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(iconSizeWFrac, iconSizeHFrac),
            Position = UDim2.fromScale(iconLeftFrac, 0.5),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = moneyIcon,
            ImageColor3 = Color3.new(1, 1, 1),
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 2,
        }),
        Amount = React.createElement("TextLabel", {
            Size = UDim2.fromScale(textWidthFrac, 0.85),
            Position = UDim2.fromScale(textLeftFrac, 0.5),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = `$` .. FormatMoney.comma(shown),
            Font = Enum.Font.FredokaOne,
            TextSize = 14,
            TextColor3 = Color3.new(1, 1, 1),
            TextTransparency = 0,
            TextStrokeTransparency = 1,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 3,
        }, {
            UIStroke = textStroke(),
        }),
    })
end

return BalanceChip
