--!strict
-- Soft vertical lift HUD icon — size is Scale of parent rail (square).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local playUiClick = require(script.Parent.Parent.util.playUiClick)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

export type Props = {
    icon: UiImageCatalog.HudIconKey,
    layoutOrder: number?,
    --- Fraction of parent width (square via aspect). Default 1 = full rail width.
    widthScale: number?,
    onActivated: (() -> ())?,
}

local HOVER_Y = -0.08
local PRESS_Y = 0.02

local function HudIconButton(props: Props): React.Node
    local w = props.widthScale or 1
    local hoverY, setHoverY = React.useState(0)
    local y = useFlipperSpring(hoverY, MotionPresets.SPRING_GENTLE)
    local hovering = React.useRef(false)
    local pressing = React.useRef(false)

    local function restY(): number
        if pressing.current then
            return PRESS_Y
        end
        if hovering.current and UserInputService.MouseEnabled then
            return HOVER_Y
        end
        return 0
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(w, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder or 0,
    }, {
        Aspect = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 1,
            DominantAxis = Enum.DominantAxis.Width,
        }),
        Hit = React.createElement("ImageButton", {
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.new(0.5, 0, 0.5 + y, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = UiImageCatalog.hudIcon(props.icon),
            ScaleType = Enum.ScaleType.Fit,
            [React.Event.Activated] = playUiClick.wrapActivated(props.onActivated),
            [React.Event.MouseEnter] = function()
                hovering.current = true
                setHoverY(restY())
            end,
            [React.Event.MouseLeave] = function()
                hovering.current = false
                pressing.current = false
                setHoverY(0)
            end,
            [React.Event.MouseButton1Down] = function()
                pressing.current = true
                setHoverY(PRESS_Y)
            end,
            [React.Event.MouseButton1Up] = function()
                pressing.current = false
                setHoverY(restY())
            end,
        }),
    })
end

return HudIconButton
