--!strict
-- Crystal comic hit confirm images (body / head|kill).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HitMarkerLogic = require(ReplicatedStorage.shared.util.HitMarkerLogic)
local HitMarkerState = require(script.Parent.Parent.Parent.core.HitMarkerState)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

local SPRING_EXPAND = { frequency = 8, dampingRatio = 0.78 }
local SPRING_FADE = { frequency = 3.4, dampingRatio = 1 }
local BASE_SIZE = 56

local function imageForKind(kind: HitMarkerLogic.HitMarkerKind): string
    if kind == "body" then
        return UiImageCatalog.combat.hitmarkerBody
    end
    -- head + kill share the gradient head master
    return UiImageCatalog.combat.hitmarkerHead
end

local function HitPulse(props: {
    kind: HitMarkerLogic.HitMarkerKind,
    token: number,
}): React.Node
    local reduce = SettingsManager.isReduceMotion()
    local opacityTarget, setOpacityTarget = React.useState(1)
    local expandTarget, setExpandTarget =
        React.useState(if reduce then 1 else HitMarkerLogic.expandPeak(props.kind))

    local opacity =
        useFlipperSpring(opacityTarget, if reduce then MotionPresets.SPRING_GENTLE else SPRING_FADE)
    local expand = useFlipperSpring(
        expandTarget,
        if reduce then MotionPresets.SPRING_GENTLE else SPRING_EXPAND
    )

    React.useEffect(function()
        setExpandTarget(1)
        local hold = if reduce then 0.04 else HitMarkerLogic.holdSec(props.kind)
        local fadeToken = task.delay(hold, function()
            setOpacityTarget(0)
        end)
        return function()
            task.cancel(fadeToken)
        end
    end, { props.token })

    if opacity < 0.02 then
        return nil
    end

    local t = math.clamp(1 - opacity, 0, 1)
    local imageT = 0.05 + t * 0.95
    local size = BASE_SIZE * expand

    return React.createElement("ImageLabel", {
        Size = UDim2.fromOffset(size, size),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = imageForKind(props.kind),
        ImageTransparency = imageT,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 8,
    })
end

local function HitMarker(): React.Node
    local snap, setSnap = React.useState(HitMarkerState.getSnapshot())

    React.useEffect(function()
        return HitMarkerState.subscribe(function()
            setSnap(HitMarkerState.getSnapshot())
        end)
    end, {})

    if snap.token <= 0 then
        return nil
    end

    return React.createElement(HitPulse, {
        key = `hm_{snap.token}`,
        kind = snap.kind,
        token = snap.token,
    })
end

return HitMarker
