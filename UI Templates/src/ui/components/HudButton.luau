--!strict
-- HUD icon: soft vertical lift on hover, sink on press (no rubber scale).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.Parent.ImageIds)
local springs = require(script.Parent.Parent.hooks.springs)
local useSpringValue = require(script.Parent.Parent.hooks.useSpringValue)

export type Props = {
	icon: ImageIds.HudIcon,
	layoutOrder: number?,
	size: UDim2?,
	onActivated: (() -> ())?,
}

local HOVER_Y = -10
local PRESS_Y = 2

local function HudButton(props: Props): React.Node
	local size = props.size or UDim2.fromOffset(88, 88)
	local y, setY = useSpringValue(0, springs.smooth)
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
		Name = props.icon,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder or 0,
	}, {
		Aspect = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),
		Hit = React.createElement("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.new(0.5, 0, 0.5, y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Image = ImageIds.Hud[props.icon],
			ScaleType = Enum.ScaleType.Fit,
			[React.Event.Activated] = props.onActivated,
			[React.Event.MouseEnter] = function()
				hovering.current = true
				setY(restY(), springs.smooth)
			end,
			[React.Event.MouseLeave] = function()
				hovering.current = false
				pressing.current = false
				setY(0, springs.soft)
			end,
			[React.Event.MouseButton1Down] = function()
				pressing.current = true
				setY(PRESS_Y, springs.soft)
			end,
			[React.Event.MouseButton1Up] = function()
				pressing.current = false
				setY(restY(), springs.smooth)
			end,
		}),
	})
end

return HudButton
