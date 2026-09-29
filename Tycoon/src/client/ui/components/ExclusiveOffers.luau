--!strict
-- Right-rail exclusive offers: spinning bg, carousel pedestals, 72h red timer.
-- Zap is soft-required: Hoarcekat mounts UI under ReplicatedStorage.UI (no sibling net/).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ExclusiveOfferLogic = require(ReplicatedStorage.shared.util.ExclusiveOfferLogic)
local ExclusiveOffersData = require(ReplicatedStorage.shared.data.ExclusiveOffers)
local HudContext = require(script.Parent.Parent.context.HudContext)
local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local playUiSound = require(script.Parent.Parent.util.playUiSound)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

type Offer = ExclusiveOffersData.Offer

type ExclusiveOfferSeenApi = {
    Fire: (boolean) -> (),
}

local farmLayout = theme.Layout.farm
local SPIN_DEG_PER_SEC = 28

local CATALOG_BY_NAME: { [string]: string } = {
    ExclusivePlatformPink = IconCatalog.ExclusivePlatformPink,
    ExclusiveRebirthCoins = IconCatalog.ExclusiveRebirthCoins,
    ExclusiveSpinBg = IconCatalog.ExclusiveSpinBg,
}

local STUB_SEEN: ExclusiveOfferSeenApi = {
    Fire = function(_seen: boolean) end,
}

local function netModuleFrom(scriptsRoot: Instance?): ModuleScript?
    local client = scriptsRoot and scriptsRoot:FindFirstChild("client")
    local net = client and client:FindFirstChild("net")
    local mod = net and net:FindFirstChild("NetClient")
    if mod and mod:IsA("ModuleScript") then
        return mod
    end
    return nil
end

local function resolveExclusiveOfferSeen(): ExclusiveOfferSeenApi
    local sibling = script.Parent.Parent.Parent:FindFirstChild("net")
    local siblingClient = sibling and sibling:FindFirstChild("NetClient")
    if siblingClient and siblingClient:IsA("ModuleScript") then
        local ok, zap = pcall(require, siblingClient)
        if ok and typeof(zap) == "table" and typeof(zap.ExclusiveOfferSeen) == "table" then
            return zap.ExclusiveOfferSeen :: ExclusiveOfferSeenApi
        end
    end

    local roots: { Instance? } = {
        if Players.LocalPlayer then Players.LocalPlayer:FindFirstChild("PlayerScripts") else nil,
        StarterPlayer:FindFirstChild("StarterPlayerScripts"),
    }
    for _, root in roots do
        local mod = netModuleFrom(root)
        if mod then
            local ok, zap = pcall(require, mod)
            if ok and typeof(zap) == "table" and typeof(zap.ExclusiveOfferSeen) == "table" then
                return zap.ExclusiveOfferSeen :: ExclusiveOfferSeenApi
            end
        end
    end
    return STUB_SEEN
end

local ExclusiveOfferSeen = resolveExclusiveOfferSeen()

local function isReduceMotion(): boolean
    local player = Players.LocalPlayer
    local roots: { Instance? } = {}
    if player then
        table.insert(roots, player:FindFirstChild("PlayerScripts"))
    end
    table.insert(roots, StarterPlayer:FindFirstChild("StarterPlayerScripts"))
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

local function titleGradient(style: ExclusiveOffersData.TitleStyle): React.Node
    local def = if style == "orange"
        then theme.Gradients.exclusiveTitleOrange
        else theme.Gradients.exclusiveTitle
    local keys = table.create(#def.keypoints)
    for i, stop in def.keypoints do
        keys[i] = ColorSequenceKeypoint.new(stop.t, stop.c)
    end
    return React.createElement("UIGradient", {
        Color = ColorSequence.new(keys),
        Rotation = def.rotation,
    })
end

local function redTimerGradient(): React.Node
    local def = theme.Gradients.exclusiveTimer
    local keys = table.create(#def.keypoints)
    for i, stop in def.keypoints do
        keys[i] = ColorSequenceKeypoint.new(stop.t, stop.c)
    end
    return React.createElement("UIGradient", {
        Color = ColorSequence.new(keys),
        Rotation = def.rotation,
    })
end

local function moneyPriceGradient(): React.Node
    local def = theme.Gradients.moneyButtonText
    local keys = table.create(#def.keypoints)
    for i, stop in def.keypoints do
        keys[i] = ColorSequenceKeypoint.new(stop.t, stop.c)
    end
    return React.createElement("UIGradient", {
        Color = ColorSequence.new(keys),
        Rotation = def.rotation,
    })
end

local function OfferCard(props: {
    offer: Offer,
    timerText: string?,
    onActivated: (offerId: string) -> (),
}): React.Node
    local offer = props.offer
    local timerText = props.timerText
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.06,
        pressScale = 0.94,
    })
    local swayRef = React.useRef(nil :: GuiObject?)

    React.useEffect(function()
        if isReduceMotion() then
            return
        end
        local preset = MotionPresets.EXCLUSIVE_SWAY
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

    local catalogId = CATALOG_BY_NAME[offer.imageCatalog] or ""
    local image = IconCatalog.resolveImage(catalogId, offer.gameAssetName)
    local title = if offer.title ~= "" then offer.title else offer.id

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
            Rotation = 0,
            ref = swayRef,
            [React.Event.Activated] = function()
                playUiSound.play("ui_click")
                props.onActivated(offer.id)
            end,
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, farmLayout.exclusiveTitleH),
                Position = UDim2.fromScale(0.5, farmLayout.exclusiveTitleY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = title,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 3,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.body,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
                Gradient = titleGradient(offer.titleStyle),
            }),
            Timer = if timerText ~= nil
                then React.createElement("TextLabel", {
                    Size = UDim2.fromScale(1, farmLayout.exclusiveTimerH),
                    Position = UDim2.fromScale(0.5, farmLayout.exclusiveTimerY),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = timerText,
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 4,
                }, {
                    Stroke = React.createElement("UIStroke", {
                        Color = theme.Colors.black,
                        Thickness = theme.Stroke.body,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                    }),
                    Gradient = redTimerGradient(),
                })
                else nil,
            Platform = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(1, farmLayout.exclusivePlatformH),
                Position = UDim2.fromScale(0.5, farmLayout.exclusivePlatformY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = image,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2,
            }),
            PriceRow = React.createElement("Frame", {
                Size = UDim2.fromScale(1, farmLayout.exclusivePriceH),
                Position = UDim2.fromScale(0.5, farmLayout.exclusivePriceY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, {
                List = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0.04, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                Robux = React.createElement("ImageLabel", {
                    Size = UDim2.fromScale(0.3, 0.95),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = IconCatalog.Robux,
                    ScaleType = Enum.ScaleType.Fit,
                    LayoutOrder = 1,
                }, {
                    Aspect = React.createElement("UIAspectRatioConstraint", {
                        AspectRatio = 1,
                        DominantAxis = Enum.DominantAxis.Height,
                    }),
                }),
                Amount = React.createElement("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.fromScale(0, 1),
                    BackgroundTransparency = 1,
                    Text = tostring(offer.robux),
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    LayoutOrder = 2,
                }, {
                    Stroke = React.createElement("UIStroke", {
                        Color = theme.Colors.black,
                        Thickness = theme.Stroke.body,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                    }),
                    Gradient = moneyPriceGradient(),
                }),
            }),
        }),
    })
end

local function ExclusiveOffers(): React.Node
    local ctx = React.useContext(HudContext)
    local hudEndsAt = ctx.hud.exclusiveOfferEndsAt or 0
    local heartOwned = ctx.hud.exclusiveHeartOwned == true
    local rebirthOwned = ctx.hud.exclusiveRebirthOwned == true
    local now, setNow = React.useState(os.time())
    local localEndsAt, setLocalEndsAt = React.useState(0)
    local spinRef = React.useRef(nil :: ImageLabel?)
    local markedRef = React.useRef(false)
    local canvasRef = React.useRef(nil :: CanvasGroup?)
    local cardScaleRef = React.useRef(nil :: UIScale?)
    local offerIndex, setOfferIndex = React.useState(1)
    local offerIndexRef = React.useRef(1)
    local animatingRef = React.useRef(false)

    offerIndexRef.current = offerIndex

    local endsAt = if hudEndsAt > 0 then hudEndsAt else localEndsAt
    local remaining = if endsAt <= 0
        then ExclusiveOfferLogic.durationSec()
        else math.max(0, endsAt - now)
    local heartTimedOut = endsAt > 0 and remaining <= 0
    local heartAvailable = not heartOwned and not heartTimedOut
    local rebirthAvailable = not rebirthOwned

    local filled: { Offer } = {}
    for _, offer in ExclusiveOffersData.all() do
        if offer.imageCatalog ~= "" and offer.robux > 0 then
            if offer.id == "pink_platform" then
                if heartAvailable then
                    table.insert(filled, offer)
                end
            elseif offer.id == "rebirth_coins" then
                if rebirthAvailable then
                    table.insert(filled, offer)
                end
            end
        end
    end

    local active = #filled > 0
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
        if not heartAvailable or markedRef.current then
            return
        end
        markedRef.current = true
        if hudEndsAt > 0 then
            setLocalEndsAt(hudEndsAt)
            return
        end
        local started = os.time() + ExclusiveOfferLogic.durationSec()
        setLocalEndsAt(started)
        ExclusiveOfferSeen.Fire(true)
    end, { heartAvailable, hudEndsAt })

    React.useEffect(function()
        if not active or isReduceMotion() then
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

    -- Keep index in range when the filled list shrinks (e.g. Heart Skin bought).
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
        if not active or not carouselOn or isReduceMotion() then
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
        local carousel = MotionPresets.EXCLUSIVE_CAROUSEL
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

    local onActivated = React.useCallback(function(offerId: string)
        ctx.onExclusiveOffer(offerId)
    end, { ctx.onExclusiveOffer })

    if not active then
        return nil :: any
    end

    local safeIndex = math.clamp(offerIndex, 1, #filled)
    local current = filled[safeIndex]
    local spinImage = IconCatalog.resolveImage(IconCatalog.ExclusiveSpinBg, "ExclusiveSpinBg")

    return React.createElement("Frame", {
        Size = UDim2.fromScale(farmLayout.exclusiveW, farmLayout.exclusiveH),
        Position = UDim2.fromScale(farmLayout.exclusivePadX, farmLayout.exclusivePadY),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 3,
    }, {
        Spin = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(farmLayout.exclusiveSpinScale, farmLayout.exclusiveSpinScale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = spinImage,
            ScaleType = Enum.ScaleType.Fit,
            ImageTransparency = 0.05,
            ZIndex = 1,
            ref = spinRef,
        }),
        Slots = React.createElement("Frame", {
            Size = UDim2.fromScale(1, farmLayout.exclusiveSlotsH),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            Card = React.createElement("CanvasGroup", {
                Size = UDim2.fromScale(farmLayout.exclusiveSlotW, 1),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
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
                    timerText = if current.id == "pink_platform"
                        then ExclusiveOfferLogic.formatCountdown(remaining)
                        else nil,
                    onActivated = onActivated,
                }),
            }),
        }),
    })
end

return ExclusiveOffers
