--!strict
-- Take-damage UI: soft red edge vignette (Valorant-like) + directional boomerang image.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local buildDamageHit = require(script.Parent.Parent.util.buildDamageHit)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

export type DamageHit = buildDamageHit.DamageHit

export type Props = {
    hits: { DamageHit },
}

local VIG_COLOR = theme.Colors.error
local RING_BODY = 390
local RING_HEAD = 450
local VIG_HOLD_SEC = 0.32

local function Edge(props: {
    size: UDim2,
    position: UDim2,
    gradientRotation: number,
    transparency: number,
}): React.Node
    return React.createElement("Frame", {
        BackgroundColor3 = VIG_COLOR,
        BackgroundTransparency = props.transparency,
        BorderSizePixel = 0,
        Size = props.size,
        Position = props.position,
        ZIndex = 20,
    }, {
        Grad = React.createElement("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.35, 0.45),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Rotation = props.gradientRotation,
        }),
    })
end

local function DamageChevron(props: {
    hit: DamageHit,
    ringSize: number,
}): React.Node
    local reduce = SettingsManager.isReduceMotion()
    local opacityTarget, setOpacityTarget = React.useState(1)
    local scaleTarget, setScaleTarget = React.useState(if reduce then 1 else 1.18)

    local opacity = useFlipperSpring(
        opacityTarget,
        if reduce then MotionPresets.SPRING_GENTLE else MotionPresets.SPRING_DAMAGE_FADE
    )
    local scale = useFlipperSpring(
        scaleTarget,
        if reduce then MotionPresets.SPRING_GENTLE else MotionPresets.SPRING_DAMAGE_POP
    )

    React.useEffect(function()
        setScaleTarget(1)
        local delaySec = if reduce then 0.08 else 0.12
        local token = task.delay(delaySec, function()
            setOpacityTarget(0)
        end)
        return function()
            task.cancel(token)
        end
    end, {})

    local wingT = math.clamp(1 - opacity, 0, 1)
    local imageT = 0.05 + wingT * 0.95
    local dirSize = math.floor(88 * scale)

    return React.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(props.ringSize * scale, props.ringSize * scale),
        BackgroundTransparency = 1,
        Rotation = props.hit.rotationDeg,
        ZIndex = 21,
    }, {
        Arrow = React.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 36),
            Size = UDim2.fromOffset(dirSize, dirSize),
            BackgroundTransparency = 1,
            Image = UiImageCatalog.combat.damageDir,
            ImageTransparency = imageT,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 22,
        }),
    })
end

local function DamageFeedbackLayer(props: Props): React.Node
    local vigTarget, setVigTarget = React.useState(0)
    local vig = useFlipperSpring(vigTarget, MotionPresets.SPRING_DAMAGE_FADE)

    local hitsKey = ""
    for _, hit in props.hits do
        hitsKey ..= hit.id .. ","
    end

    React.useEffect(function()
        if #props.hits == 0 then
            setVigTarget(0)
            return
        end
        local best = 0
        for _, hit in props.hits do
            if hit.strength > best then
                best = hit.strength
            end
        end
        setVigTarget(best)
        local token = task.delay(VIG_HOLD_SEC, function()
            setVigTarget(0)
        end)
        return function()
            task.cancel(token)
        end
    end, { hitsKey })

    -- Edge opacity: vig 0..1 → BackgroundTransparency (0 = solid). Keep center clear.
    local edgeT = 1 - math.clamp(vig * 0.9, 0, 0.82)

    local chevrons: { [string]: React.Node } = {}
    for _, hit in props.hits do
        chevrons["Hit_" .. hit.id] = React.createElement(DamageChevron, {
            hit = hit,
            ringSize = if hit.headshot then RING_HEAD else RING_BODY,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 20,
        Active = false,
    }, {
        Vignette = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 20,
            Visible = vig > 0.02,
        }, {
            Top = React.createElement(Edge, {
                size = UDim2.new(1, 0, 0.24, 0),
                position = UDim2.fromScale(0, 0),
                gradientRotation = 90,
                transparency = edgeT,
            }),
            Bottom = React.createElement(Edge, {
                size = UDim2.new(1, 0, 0.24, 0),
                position = UDim2.new(0, 0, 0.76, 0),
                gradientRotation = 270,
                transparency = edgeT,
            }),
            Left = React.createElement(Edge, {
                size = UDim2.new(0.18, 0, 1, 0),
                position = UDim2.fromScale(0, 0),
                gradientRotation = 0,
                transparency = edgeT,
            }),
            Right = React.createElement(Edge, {
                size = UDim2.new(0.18, 0, 1, 0),
                position = UDim2.new(0.82, 0, 0, 0),
                gradientRotation = 180,
                transparency = edgeT,
            }),
        }),
        Chevrons = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 21,
        }, chevrons),
    })
end

return DamageFeedbackLayer
