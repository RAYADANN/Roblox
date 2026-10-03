--!strict
-- Right-rail boost offers: LuckyX2 / LuckyX4 / MoneyX2Gold carousel.
-- 24h sale (R$10 + strikethrough was) → then full price, no timer, until bought.
-- Price layout matches shop RobuxButton (sale above, main price below).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BoostOfferDatabase = require(ReplicatedStorage.shared.data.BoostOfferDatabase)
local BoostOfferLogic = require(ReplicatedStorage.shared.util.BoostOfferLogic)
local HudContext = require(script.Parent.Parent.Parent.context.HudContext)
local MotionPresets = require(script.Parent.Parent.Parent.motion.MotionPresets)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local shopAssets = require(script.Parent.Parent.Parent.shop.assets)
local shopTokens = require(script.Parent.Parent.Parent.shop.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

type Offer = BoostOfferDatabase.BoostOffer

--- Same spinning backdrop as HeroReveal.
local SPIN_IMAGE = "rbxassetid://101824724626288"
local SPIN_DEG_PER_SEC = 28

local LAYOUT = {
    padX = 0.9,
    padY = 0.38,
    w = 0.225,
    h = 0.39,
    --- Room for hover scale inside the rail frame.
    cardScale = 0.88,
    spinScale = 0.9,
    titleH = 0.14,
    titleY = 0.04,
    timerH = 0.1,
    timerY = 0.16,
    artH = 0.48,
    artY = 0.28,
    priceH = 0.2,
    priceY = 0.78,
}

-- Same idea as shop RobuxButton PRICE / SALE blocks.
local PRICE = {
    size = UDim2.fromScale(0, 1),
    pos = UDim2.fromScale(0.5, 0.55),
    anchor = Vector2.new(0.5, 0.5),
    gap = 0,
}
local SALE = {
    size = UDim2.fromScale(0, 0.48),
    pos = UDim2.fromScale(0.58, 0.08),
    anchor = Vector2.new(0.5, 0.5),
    gap = 0,
    strikeH = 0.14,
    strikeRot = -12,
}

local function playClick()
    local uiRoot = script.Parent.Parent.Parent
    local client = uiRoot.Parent
    local core = if client then client:FindFirstChild("core") else nil
    if core == nil then
        core = uiRoot:FindFirstChild("core")
    end
    local mod = core and core:FindFirstChild("SoundManager")
    if mod and mod:IsA("ModuleScript") then
        local ok, sound = pcall(require, mod)
        if ok and sound and typeof(sound.play) == "function" then
            sound.play("ui_click")
        end
    end
end

local function robuxRow(opts: {
    text: string,
    color: Color3?,
    iconColor: Color3?,
    gap: number,
    zIndex: number,
}): React.Node
    return React.createElement("Frame", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = opts.zIndex,
    }, {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(opts.gap, 0),
        }),
        Icon = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = shopAssets.robux,
            ImageColor3 = opts.iconColor or Color3.fromRGB(255, 255, 255),
            ScaleType = Enum.ScaleType.Fit,
            LayoutOrder = 1,
            ZIndex = opts.zIndex,
        }, {
            Aspect = React.createElement("UIAspectRatioConstraint", {
                AspectRatio = 1,
                DominantAxis = Enum.DominantAxis.Height,
            }),
        }),
        Label = React.createElement(StrokeText, {
            text = opts.text,
            color = opts.color,
            strokeThickness = shopTokens.strokeBtn,
            size = UDim2.fromScale(0, 1),
            automaticSize = Enum.AutomaticSize.X,
            textWrapped = false,
            textXAlignment = Enum.TextXAlignment.Left,
            layoutOrder = 2,
            zIndex = opts.zIndex,
        }),
    })
end

local function OfferCard(props: {
    offer: Offer,
    timerText: string?,
    price: number,
    originalPrice: number?,
    onActivated: (offerId: string) -> (),
}): React.Node
    local offer = props.offer
    local hasSale = props.originalPrice ~= nil
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.04,
        pressScale = 0.96,
    })
    local swayRef = React.useRef(nil :: GuiObject?)

    React.useEffect(function()
        local preset = MotionPresets.BOOST_SWAY
        local t0 = os.clock()
        local conn = RunService.RenderStepped:Connect(function()
            local live = swayRef.current
            if live == nil then
                return
            end
            local wave = math.sin((os.clock() - t0) * (math.pi * 2 / preset.periodSec))
            live.Rotation = wave * preset.amplitudeDeg
        end)
        return function()
            conn:Disconnect()
            local live = swayRef.current
            if live then
                live.Rotation = 0
            end
        end
    end, {})

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    }, {
        Scale = React.createElement("UIScale", { Scale = hoverScale }),
        Hit = React.createElement("ImageButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = "",
            Active = true,
            ref = swayRef,
            [React.Event.Activated] = function()
                playClick()
                props.onActivated(offer.id)
            end,
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, LAYOUT.titleH),
                Position = UDim2.fromScale(0.5, LAYOUT.titleY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = offer.title,
                Font = shopTokens.font,
                TextScaled = true,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 3,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.new(0, 0, 0),
                    Thickness = 0.08,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
            }),
            Timer = if props.timerText ~= nil
                then React.createElement("TextLabel", {
                    Size = UDim2.fromScale(1, LAYOUT.timerH),
                    Position = UDim2.fromScale(0.5, LAYOUT.timerY),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = props.timerText,
                    Font = shopTokens.font,
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 80, 80),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 4,
                }, {
                    Stroke = React.createElement("UIStroke", {
                        Color = Color3.new(0, 0, 0),
                        Thickness = 0.08,
                        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                    }),
                })
                else nil,
            Art = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(1, LAYOUT.artH),
                Position = UDim2.fromScale(0.5, LAYOUT.artY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = offer.image,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2,
            }),
            PriceRow = React.createElement("Frame", {
                Size = UDim2.fromScale(1, LAYOUT.priceH),
                Position = UDim2.fromScale(0.5, LAYOUT.priceY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = false,
                ZIndex = 3,
            }, {
                Sale = if hasSale
                    then React.createElement("Frame", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = SALE.size,
                        Position = SALE.pos,
                        AnchorPoint = SALE.anchor,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 4,
                    }, {
                        Row = robuxRow({
                            text = tostring(props.originalPrice :: number),
                            color = shopTokens.saleRed,
                            iconColor = shopTokens.saleRed,
                            gap = SALE.gap,
                            zIndex = 4,
                        }),
                        Strike = React.createElement("Frame", {
                            Size = UDim2.fromScale(1, SALE.strikeH),
                            Position = UDim2.fromScale(0.5, 0.5),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundColor3 = shopTokens.titleShadow,
                            BorderSizePixel = 0,
                            Rotation = SALE.strikeRot,
                            ZIndex = 5,
                        }),
                    })
                    else nil,
                Price = React.createElement("Frame", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = PRICE.size,
                    Position = PRICE.pos,
                    AnchorPoint = PRICE.anchor,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }, {
                    Row = robuxRow({
                        text = tostring(props.price),
                        gap = PRICE.gap,
                        zIndex = 3,
                    }),
                }),
            }),
        }),
    })
end

local function BoostOffers(): React.Node
    local ctx = React.useContext(HudContext)
    local hud = ctx.hud
    local hudEndsAt = hud.boostOfferEndsAt or 0
    local now, setNow = React.useState(os.time())
    local localEndsAt, setLocalEndsAt = React.useState(0)
    local markedRef = React.useRef(false)
    local canvasRef = React.useRef(nil :: CanvasGroup?)
    local cardScaleRef = React.useRef(nil :: UIScale?)
    local spinRef = React.useRef(nil :: ImageLabel?)
    local offerIndex, setOfferIndex = React.useState(1)
    local offerIndexRef = React.useRef(1)
    local animatingRef = React.useRef(false)

    offerIndexRef.current = offerIndex

    local ownership = {
        ownsLuckyX2 = hud.ownsLuckyX2 == true,
        ownsLuckyX4 = hud.ownsLuckyX4 == true,
        ownsMoneyX2 = hud.ownsMoneyX2 == true,
    }
    local endsAt = if hudEndsAt > 0 then hudEndsAt else localEndsAt
    local remaining = if endsAt <= 0
        then BoostOfferLogic.durationSec()
        else math.max(0, endsAt - now)
    local seenAt = if endsAt > 0 then endsAt - BoostOfferLogic.durationSec() else 0
    local saleActive = BoostOfferLogic.isSaleActive(seenAt, now)
    local filled = BoostOfferLogic.availableOffers(ownership)

    -- Hide during FTUE; start sale timer only after tutorial ends.
    local tutorialDone = hud.tutorialCompleted == true
    local active = tutorialDone and #filled > 0
    local carouselOn = #filled >= 2

    React.useEffect(function()
        if hudEndsAt > 0 and hudEndsAt ~= localEndsAt then
            setLocalEndsAt(hudEndsAt)
        end
    end, { hudEndsAt })

    React.useEffect(function()
        if not active then
            return
        end
        local last = os.time()
        local conn = RunService.Heartbeat:Connect(function()
            local t = os.time()
            if t ~= last then
                last = t
                setNow(t)
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, { active })

    React.useEffect(function()
        if not active then
            return
        end
        local conn = RunService.RenderStepped:Connect(function(dt)
            local label = spinRef.current
            if label == nil then
                return
            end
            label.Rotation = (label.Rotation + SPIN_DEG_PER_SEC * dt) % 360
        end)
        return function()
            conn:Disconnect()
        end
    end, { active })

    React.useEffect(function()
        if not active or markedRef.current then
            return
        end
        markedRef.current = true
        if hudEndsAt > 0 then
            setLocalEndsAt(hudEndsAt)
            return
        end
        setLocalEndsAt(os.time() + BoostOfferLogic.durationSec())
        if ctx.onBoostOfferSeen then
            ctx.onBoostOfferSeen()
        end
    end, { active, hudEndsAt })

    React.useEffect(function()
        if #filled == 0 then
            return
        end
        if offerIndex > #filled then
            setOfferIndex(1)
            offerIndexRef.current = 1
        end
    end, { #filled, offerIndex })

    React.useEffect(function()
        if not active or not carouselOn then
            local canvas = canvasRef.current
            local scale = cardScaleRef.current
            if canvas then
                canvas.GroupTransparency = 0
            end
            if scale then
                scale.Scale = 1
            end
            return
        end
        local carousel = MotionPresets.BOOST_CAROUSEL
        local cancelled = false
        local count = #filled

        local function playSwap()
            if cancelled or animatingRef.current then
                return
            end
            local canvas = canvasRef.current
            local scale = cardScaleRef.current
            if canvas == nil or scale == nil then
                return
            end
            animatingRef.current = true
            local fadeOut = TweenService:Create(canvas, carousel.fadeOut, {
                GroupTransparency = 1,
            })
            fadeOut.Completed:Connect(function()
                if cancelled then
                    animatingRef.current = false
                    return
                end
                local nextIndex = (offerIndexRef.current % count) + 1
                offerIndexRef.current = nextIndex
                setOfferIndex(nextIndex)
                scale.Scale = carousel.scaleFrom
                canvas.GroupTransparency = 1
                local fadeInT = TweenService:Create(canvas, carousel.fadeIn, {
                    GroupTransparency = 0,
                })
                local scaleIn = TweenService:Create(scale, carousel.fadeIn, {
                    Scale = 1,
                })
                fadeInT:Play()
                scaleIn:Play()
                fadeInT.Completed:Connect(function()
                    animatingRef.current = false
                end)
            end)
            fadeOut:Play()
        end

        local thread = task.spawn(function()
            while not cancelled do
                task.wait(carousel.dwellSec)
                if cancelled then
                    break
                end
                playSwap()
            end
        end)

        return function()
            cancelled = true
            task.cancel(thread)
            animatingRef.current = false
            local canvas = canvasRef.current
            local scale = cardScaleRef.current
            if canvas then
                canvas.GroupTransparency = 0
            end
            if scale then
                scale.Scale = 1
            end
        end
    end, { active, carouselOn, #filled })

    if not active then
        return nil :: any
    end

    local safeIndex = math.clamp(offerIndex, 1, #filled)
    local current = filled[safeIndex]
    local display = BoostOfferLogic.displayPrice(current, saleActive)
    local timerText = if saleActive then BoostOfferLogic.formatCountdown(remaining) else nil

    return React.createElement("Frame", {
        Size = UDim2.fromScale(LAYOUT.w, LAYOUT.h),
        Position = UDim2.fromScale(LAYOUT.padX, LAYOUT.padY),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 3,
    }, {
        Spin = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(LAYOUT.spinScale, LAYOUT.spinScale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = SPIN_IMAGE,
            ScaleType = Enum.ScaleType.Fit,
            ImageTransparency = 0.08,
            ZIndex = 1,
            ref = spinRef,
        }),
        Slots = React.createElement("Frame", {
            Size = UDim2.fromScale(LAYOUT.cardScale, LAYOUT.cardScale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = false,
            ZIndex = 2,
        }, {
            Card = React.createElement("CanvasGroup", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                GroupTransparency = 0,
                ref = canvasRef,
            }, {
                Scale = React.createElement("UIScale", {
                    Scale = 1,
                    ref = cardScaleRef,
                }),
                Offer = React.createElement(OfferCard, {
                    offer = current,
                    timerText = timerText,
                    price = display.price,
                    originalPrice = display.originalPrice,
                    onActivated = function(offerId: string)
                        if ctx.onBoostOffer then
                            ctx.onBoostOffer(offerId)
                        end
                    end,
                }),
            }),
        }),
    })
end

return BoostOffers
