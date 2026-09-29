--!strict
-- React port of StarterGui.HUD (right icon rail + coins chip + bag).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ExclusiveOffers = require(script.Parent.ExclusiveOffers)
local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local HudContext = require(script.Parent.Parent.context.HudContext)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local ItemsCountChip = require(script.Parent.ItemsCountChip)
local MoneyOfferButtons = require(script.Parent.MoneyOfferButtons)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local RebirthLogic = require(ReplicatedStorage.shared.util.RebirthLogic)
local playUiSound = require(script.Parent.Parent.util.playUiSound)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

local STROKE_TEAL = Color3.fromRGB(0, 39, 56)
local farmLayout = theme.Layout.farm
local BALANCE_POP_PEAK = 1.08

-- Soft resolve: FarmHud also loads under ReplicatedStorage.UI (Hoarcekat).
local function isReduceMotion(): boolean
    local scripts = game:GetService("Players").LocalPlayer
    local roots: { Instance? } = {}
    if scripts then
        table.insert(roots, scripts:FindFirstChild("PlayerScripts"))
    end
    table.insert(roots, game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"))
    for _, root in roots do
        local client = root and root:FindFirstChild("client")
        local core = client and client:FindFirstChild("core")
        local mod = core and core:FindFirstChild("SettingsManager")
        if mod and mod:IsA("ModuleScript") then
            local ok, settings = pcall(require, mod)
            if
                ok
                and typeof(settings) == "table"
                and typeof(settings.isReduceMotion) == "function"
            then
                return settings.isReduceMotion() == true
            end
        end
    end
    return false
end

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

local function billboardPriceGradient(): React.Node
    local def = theme.Gradients.billboardPrice
    local keys = table.create(#def.keypoints)
    for i, stop in def.keypoints do
        keys[i] = ColorSequenceKeypoint.new(stop.t, stop.c)
    end
    return React.createElement("UIGradient", {
        Color = ColorSequence.new(keys),
        Rotation = def.rotation,
    })
end

local function multLabel(rebirths: number): string
    local mult = RebirthLogic.valueMultiplier(rebirths)
    if mult == math.floor(mult) then
        return `x{math.floor(mult)}`
    end
    return `x{string.format("%.1f", mult)}`
end

type BalanceChipProps = {
    coins: number,
    rebirths: number,
}

local function BalanceChip(props: BalanceChipProps): React.Node
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
    local multW = farmLayout.balanceMultW
    local multRightFrac = farmLayout.balanceMultRightPx / barPxW
    local textWidthFrac = 1 - textLeftFrac - multW - multRightFrac
    local moneyBarBg = IconCatalog.resolveImage(IconCatalog.MoneyBarBg, "BalanceBarBg")
    local shown = math.floor(display + 0.5)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(farmLayout.balanceW, farmLayout.balanceH),
        Position = UDim2.fromScale(farmLayout.balancePadX, 1 - farmLayout.balancePadBottom),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
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
            Image = IconCatalog.Money,
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
        Mult = React.createElement("TextLabel", {
            Size = UDim2.fromScale(multW, 0.72),
            Position = UDim2.fromScale(1 - multRightFrac, 0.5),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = multLabel(props.rebirths),
            Font = Enum.Font.FredokaOne,
            TextSize = 14,
            TextColor3 = theme.Colors.white,
            TextTransparency = 0,
            TextStrokeTransparency = 1,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 4,
        }, {
            UIStroke = textStroke(),
            Grad = billboardPriceGradient(),
        }),
    })
end

type HudIconDef = {
    id: string,
    image: string,
    label: string,
    labelH: number,
    layoutOrder: number,
}

local RAIL: { HudIconDef } = {
    {
        id = "Index",
        image = IconCatalog.Index,
        label = "INDEX",
        labelH = 0.5,
        layoutOrder = 1,
    },
    {
        id = "Rebirth",
        image = IconCatalog.Rebirth,
        label = "REBIRTH",
        labelH = 0.5,
        layoutOrder = 2,
    },
}

local function HudIcon(def: HudIconDef): React.Node
    local ctx = React.useContext(HudContext)
    local scale, handlers = useHoverPress({
        hoverScale = MotionPresets.HOVER_SCALE,
        pressScale = MotionPresets.PRESS_SCALE,
    })
    local attentionRef = React.useRef(nil :: UIScale?)
    local canRebirth = def.id == "Rebirth"
        and RebirthLogic.canAfford(ctx.hud.coins, ctx.hud.rebirths)

    React.useEffect(function()
        if def.id ~= "Rebirth" then
            return
        end
        if not canRebirth or isReduceMotion() then
            local scaleInst = attentionRef.current
            if scaleInst then
                scaleInst.Scale = 1
            end
            return
        end
        local preset = MotionPresets.REBIRTH_READY
        local t0 = os.clock()
        local conn = RunService.Heartbeat:Connect(function()
            local live = attentionRef.current
            if live == nil then
                return
            end
            local wave = 0.5 + 0.5 * math.sin((os.clock() - t0) * (math.pi * 2 / preset.periodSec))
            live.Scale = 1 + preset.amplitude * wave
        end)
        return function()
            conn:Disconnect()
            local live = attentionRef.current
            if live then
                live.Scale = 1
            end
        end
    end, { canRebirth, def.id } :: { any })

    return React.createElement("TextButton", {
        Size = UDim2.fromScale(1, 0.45),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = def.layoutOrder,
        [React.Event.Activated] = function()
            playUiSound.play("ui_click")
            if def.id == "Index" then
                ctx.setRebirthOpen(false)
                ctx.setIndexOpen(true)
            elseif def.id == "Rebirth" then
                ctx.setIndexOpen(false)
                ctx.setRebirthOpen(true)
            end
        end,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Face = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            AttentionScale = if def.id == "Rebirth"
                then React.createElement("UIScale", {
                    Scale = 1,
                    ref = attentionRef,
                })
                else nil,
            Image = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = def.image,
                ImageColor3 = Color3.new(1, 1, 1),
                ImageTransparency = 0,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 1,
            }),
            Price = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, def.labelH, 0),
                Position = UDim2.fromScale(0.5, 0.9),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = def.label,
                Font = Enum.Font.FredokaOne,
                TextSize = 14,
                TextColor3 = Color3.new(1, 1, 1),
                TextTransparency = 0,
                TextStrokeTransparency = 1,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 2,
            }, {
                UIStroke = textStroke(),
            }),
        }),
    })
end

local function FarmHud(): React.Node
    local ctx = React.useContext(HudContext)
    local hud = ctx.hud

    local railChildren: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 15),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for _, def in RAIL do
        railChildren[def.id] = React.createElement(HudIcon, def)
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Frame = React.createElement("Frame", {
            Size = UDim2.fromScale(farmLayout.railW, farmLayout.railH),
            Position = UDim2.fromScale(farmLayout.railPadX, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, railChildren),
        MoneyOffers = React.createElement(MoneyOfferButtons),
        Exclusive = React.createElement(ExclusiveOffers),
        Coins = React.createElement(BalanceChip, {
            coins = hud.coins,
            rebirths = hud.rebirths,
        }),
        Items = React.createElement(ItemsCountChip, { count = hud.backpackEggs }),
        TutorialTest = React.createElement("TextButton", {
            Size = UDim2.fromScale(farmLayout.tutorialTestW, farmLayout.tutorialTestH),
            Position = UDim2.fromScale(farmLayout.tutorialTestPadX, farmLayout.tutorialTestPadY),
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = theme.Colors.btnBg,
            BorderSizePixel = 0,
            Text = "TUTORIAL",
            Font = Enum.Font.FredokaOne,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            AutoButtonColor = false,
            ZIndex = 5,
            [React.Event.Activated] = function()
                playUiSound.play("ui_click")
                ctx.startTutorial()
            end,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0.2, 0),
            }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.medium,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        }),
    })
end

return FarmHud
