--!strict
-- Demo button: root TextButton owns stroke / scale / shadow; ImageLabel = chrome only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.Parent.ImageIds)
local Shadow = require(script.Parent.Parent.util.Shadow)
local springs = require(script.Parent.Parent.hooks.springs)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useMountAppear = require(script.Parent.Parent.hooks.useMountAppear)
local useSpringValue = require(script.Parent.Parent.hooks.useSpringValue)

export type MotionKind = "soft" | "pop" | "tilt" | "lift" | "shake" | "slide"

export type Props = {
    motion: MotionKind,
    label: string?,
    tone: theme.ActionTone?,
    size: UDim2?,
    layoutOrder: number?,
    appearDelay: number?,
}

local function useTilt(enabled: boolean): (number, {
    onMouseEnter: () -> (),
    onMouseLeave: () -> (),
})
    local rot, setRot = useSpringValue(0, springs.soft)
    return rot,
        {
            onMouseEnter = function()
                if enabled and UserInputService.MouseEnabled then
                    setRot(-5, springs.soft)
                end
            end,
            onMouseLeave = function()
                setRot(0, springs.soft)
            end,
        }
end

local function useLift(enabled: boolean): (number, {
    onMouseEnter: () -> (),
    onMouseLeave: () -> (),
    onMouseDown: () -> (),
    onMouseUp: () -> (),
})
    local y, setY = useSpringValue(0, springs.soft)
    local hovering = React.useRef(false)

    return y,
        {
            onMouseEnter = function()
                hovering.current = true
                if enabled and UserInputService.MouseEnabled then
                    setY(-8, springs.soft)
                end
            end,
            onMouseLeave = function()
                hovering.current = false
                setY(0, springs.soft)
            end,
            onMouseDown = function()
                if enabled then
                    setY(-2, springs.soft)
                end
            end,
            onMouseUp = function()
                if enabled then
                    setY(if hovering.current then -8 else 0, springs.soft)
                end
            end,
        }
end

local function useShake(): (number, () -> ())
    local rot, setRot = useSpringValue(0, springs.bouncy)

    local function kick()
        setRot(7, springs.bouncy)
        task.delay(0.1, function()
            setRot(-5, springs.bouncy)
            task.delay(0.1, function()
                setRot(0, springs.soft)
            end)
        end)
    end

    return rot, kick
end

local function useSlideIn(delaySec: number, enabled: boolean): number
    local x, setX = useSpringValue(if enabled then -40 else 0, springs.soft)

    React.useEffect(function()
        if not enabled then
            return function() end
        end
        local cancelled = false
        task.delay(delaySec, function()
            if not cancelled then
                setX(0, springs.soft)
            end
        end)
        return function()
            cancelled = true
        end
    end, {})

    return x
end

local function MotionButton(props: Props): React.Node
    local motion = props.motion
    local tone: theme.ActionTone = props.tone or "equip"
    local label = props.label or string.upper(motion)
    local size = props.size or UDim2.fromOffset(200, 56)
    local delaySec = props.appearDelay or 0

    local appearScale, appearTransparency = useMountAppear({
        delay = delaySec,
        fromScale = if motion == "pop" then 0.78 else 0.94,
        frequency = if motion == "pop" then springs.bouncy.frequency else springs.soft.frequency,
        dampingRatio = if motion == "pop"
            then springs.bouncy.dampingRatio
            else springs.soft.dampingRatio,
    })

    local softScale, softHandlers = useHoverPress({
        hoverScale = 1.03,
        pressScale = 0.97,
        spring = springs.soft,
        disabled = motion ~= "soft" and motion ~= "slide",
    })
    local popScale, popHandlers = useHoverPress({
        hoverScale = 1.06,
        pressScale = 0.9,
        spring = springs.bouncy,
        disabled = motion ~= "pop",
    })

    local tilt, tiltHandlers = useTilt(motion == "tilt")
    local liftY, liftHandlers = useLift(motion == "lift")
    local shakeRot, shakeKick = useShake()
    local slideX = useSlideIn(delaySec, motion == "slide")

    local motionScale = 1
    local rotation = 0
    local pos = UDim2.fromScale(0, 0)
    local onMouseEnter: (() -> ())? = nil
    local onMouseLeave: (() -> ())? = nil
    local onMouseDown: (() -> ())? = nil
    local onMouseUp: (() -> ())? = nil
    local onActivated: (() -> ())? = nil

    if motion == "soft" or motion == "slide" then
        motionScale = softScale
        onMouseEnter = softHandlers.onMouseEnter
        onMouseLeave = softHandlers.onMouseLeave
        onMouseDown = softHandlers.onMouseDown
        onMouseUp = softHandlers.onMouseUp
        if motion == "slide" then
            pos = UDim2.fromOffset(slideX, 0)
        end
    elseif motion == "pop" then
        motionScale = popScale
        onMouseEnter = popHandlers.onMouseEnter
        onMouseLeave = popHandlers.onMouseLeave
        onMouseDown = popHandlers.onMouseDown
        onMouseUp = popHandlers.onMouseUp
    elseif motion == "tilt" then
        rotation = tilt
        onMouseEnter = tiltHandlers.onMouseEnter
        onMouseLeave = tiltHandlers.onMouseLeave
    elseif motion == "lift" then
        pos = UDim2.fromOffset(0, liftY)
        onMouseEnter = liftHandlers.onMouseEnter
        onMouseLeave = liftHandlers.onMouseLeave
        onMouseDown = liftHandlers.onMouseDown
        onMouseUp = liftHandlers.onMouseUp
    elseif motion == "shake" then
        rotation = shakeRot
        onActivated = shakeKick
    end

    local scale = appearScale * motionScale
    local chrome = ImageIds.Action[tone].linear

    return React.createElement("TextButton", {
        Size = size,
        Position = pos,
        Rotation = rotation,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        LayoutOrder = props.layoutOrder,
        [React.Event.Activated] = onActivated,
        [React.Event.MouseEnter] = onMouseEnter,
        [React.Event.MouseLeave] = onMouseLeave,
        [React.Event.MouseButton1Down] = onMouseDown,
        [React.Event.MouseButton1Up] = onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Shadow = Shadow.element(theme.Shadow.button),
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(theme.Radius.button, 0),
        }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.button,
            Transparency = appearTransparency,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
        Chrome = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = chrome,
            ImageTransparency = appearTransparency,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 0,
        }),
        Label = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = label,
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            TextTransparency = appearTransparency,
            ZIndex = 2,
        }, {
            Pad = React.createElement("UIPadding", {
                PaddingLeft = UDim.new(0.06, 0),
                PaddingRight = UDim.new(0.06, 0),
            }),
            Constraint = React.createElement("UITextSizeConstraint", {
                MinTextSize = 10,
                MaxTextSize = 42,
            }),
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                Transparency = appearTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        }),
    })
end

return MotionButton
