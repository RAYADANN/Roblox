--!strict
-- Valorant-style kill confirm: spinning ring + skull (staggered pop + fade).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local KillBannerState = require(script.Parent.Parent.Parent.core.KillBannerState)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

local HOLD_SEC = 0.7
local RING_SPIN_DEG_PER_SEC = 220
local RING_SIZE = 260
-- Keep skull at previous absolute size (0.55 * 360).
local ICON_SIZE = 198

local SPRING_FADE_IN = { frequency = 5.8, dampingRatio = 1 }
local SPRING_FADE_OUT = { frequency = 2.2, dampingRatio = 1 }
local SPRING_RING = { frequency = 6.2, dampingRatio = 0.78 }
local SPRING_ICON = { frequency = 8.2, dampingRatio = 0.58 }

local function KillPulse(props: { token: number }): React.Node
    local reduce = SettingsManager.isReduceMotion()
    local opacityTarget, setOpacityTarget = React.useState(0)
    local ringScaleTarget, setRingScaleTarget = React.useState(if reduce then 1 else 0.7)
    local iconScaleTarget, setIconScaleTarget = React.useState(if reduce then 1 else 0.15)
    local ringRef = React.useRef(nil :: ImageLabel?)

    local opacitySpring = if opacityTarget <= 0.01 then SPRING_FADE_OUT else SPRING_FADE_IN
    local opacity = useFlipperSpring(
        opacityTarget,
        if reduce then MotionPresets.SPRING_GENTLE else opacitySpring
    )
    local ringScale = useFlipperSpring(
        ringScaleTarget,
        if reduce then MotionPresets.SPRING_GENTLE else SPRING_RING
    )
    local iconScale = useFlipperSpring(
        iconScaleTarget,
        if reduce then MotionPresets.SPRING_GENTLE else SPRING_ICON
    )

    React.useEffect(function()
        local tokens: { thread } = {}
        local function later(sec: number, fn: () -> ())
            table.insert(tokens, task.delay(sec, fn))
        end

        setOpacityTarget(1)
        if reduce then
            setRingScaleTarget(1)
            setIconScaleTarget(1)
        else
            setRingScaleTarget(1.1)
            later(0.1, function()
                setRingScaleTarget(1)
            end)
            later(0.05, function()
                setIconScaleTarget(1.32)
            end)
            later(0.16, function()
                setIconScaleTarget(1)
            end)
        end

        local hold = if reduce then 0.14 else HOLD_SEC
        later(hold, function()
            setOpacityTarget(0)
            if not reduce then
                setRingScaleTarget(0.9)
                setIconScaleTarget(0.72)
            end
        end)

        return function()
            for _, t in tokens do
                task.cancel(t)
            end
        end
    end, { props.token })

    React.useEffect(function()
        if reduce then
            return
        end
        local conn = RunService.RenderStepped:Connect(function(dt)
            local ring = ringRef.current
            if ring then
                ring.Rotation = (ring.Rotation + RING_SPIN_DEG_PER_SEC * dt) % 360
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, { props.token, reduce })

    if opacity < 0.02 then
        return nil
    end

    local appear = math.clamp(opacity, 0, 1)
    local ringT = 1 - math.pow(appear, 0.85)
    local iconT = 1 - math.pow(appear, 1.15)
    local ringPx = RING_SIZE * ringScale
    local iconPx = ICON_SIZE * iconScale
    local boxPx = math.max(ringPx, iconPx)

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(boxPx, boxPx),
        Position = UDim2.fromScale(0.5, 0.32),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 30,
    }, {
        Ring = React.createElement("ImageLabel", {
            Size = UDim2.fromOffset(ringPx, ringPx),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = UiImageCatalog.combat.killRing,
            ImageTransparency = ringT,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 30,
            ref = ringRef,
        }),
        Icon = React.createElement("ImageLabel", {
            Size = UDim2.fromOffset(iconPx, iconPx),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = UiImageCatalog.combat.killIcon,
            ImageTransparency = iconT,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 31,
        }),
    })
end

local function KillBanner(): React.Node
    local snap, setSnap = React.useState(KillBannerState.getSnapshot())

    React.useEffect(function()
        return KillBannerState.subscribe(function()
            setSnap(KillBannerState.getSnapshot())
        end)
    end, {})

    if snap.token <= 0 then
        return nil
    end

    return React.createElement(KillPulse, {
        key = `kb_{snap.token}`,
        token = snap.token,
    })
end

return KillBanner
