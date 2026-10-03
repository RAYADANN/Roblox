--!strict
-- HUD icon button: image + label. Optional attention pulse when reward claimable.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    image: string,
    label: string,
    position: UDim2,
    onActivated: (() -> ())?,
    --- Soft pulse + wobble so the player notices a claimable reward.
    attention: boolean?,
}

local ATTENTION_PULSE = 0.12
local ATTENTION_SPEED = 4.2
local ATTENTION_WOBBLE_DEG = 7

local function HudIcon(props: Props): React.Node
    local I = SG.icons
    local attention = props.attention == true
    local hoverScale, handlers = useHoverPress({ hoverScale = 1.08 })

    local pulse, setPulse = React.useState(1)
    local wobble, setWobble = React.useState(0)

    React.useEffect(function()
        if not attention then
            setPulse(1)
            setWobble(0)
            return nil
        end
        local t0 = os.clock()
        local conn = RunService.RenderStepped:Connect(function()
            local t = os.clock() - t0
            setPulse(1 + ATTENTION_PULSE * (0.5 + 0.5 * math.sin(t * ATTENTION_SPEED)))
            setWobble(ATTENTION_WOBBLE_DEG * math.sin(t * (ATTENTION_SPEED * 0.85)))
        end)
        return function()
            conn:Disconnect()
        end
    end, { attention })

    local scale = hoverScale * pulse

    return React.createElement("ImageButton", {
        Size = I.buttonSize,
        Position = props.position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        AutoButtonColor = false,
        Rotation = wobble,
        ZIndex = if attention then 3 else 2,
        [React.Event.Activated] = props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Icon = React.createElement("ImageLabel", {
            Size = I.icon.size,
            Position = I.icon.pos,
            AnchorPoint = I.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = props.image,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 1,
        }),
        Label = React.createElement(StrokeText, {
            text = props.label,
            strokeThickness = tokens.strokeIcon,
            size = I.label.size,
            position = I.label.pos,
            anchorPoint = I.label.anchor,
            uniformFitRef = "REWARDS",
            zIndex = 2,
            color = if attention then tokens.attentionGlow else nil,
        }),
    })
end

return HudIcon
