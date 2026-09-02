--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local Icon = require(script.Parent.Icon)

export type Props = {
	token: number,
	message: string?,
}

local function StealAlertVignette(props: Props): React.Node
	local layout = useLayout()
	local alpha, setAlpha = React.useState(1)
	local visible, setVisible = React.useState(false)

	React.useEffect(function()
		if props.token <= 0 then
			return
		end
		setVisible(true)
		local motor = Flipper.SingleMotor.new(1, false)
		local connection = motor:onStep(setAlpha)
		motor:start()
		motor:setGoal(Flipper.Spring.new(0.08, MotionPresets.Spring.snappy))
		local fadeThread = task.delay(0.8, function()
			motor:setGoal(Flipper.Spring.new(1, MotionPresets.Spring.gentle))
		end)
		local hideThread = task.delay(1.8, function()
			setVisible(false)
		end)
		return function()
			pcall(task.cancel, fadeThread)
			pcall(task.cancel, hideThread)
			connection:disconnect()
			motor:destroy()
		end
	end, { props.token })

	if not visible then
		return nil
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Semantic.danger,
		BackgroundTransparency = math.clamp(alpha + 0.62, 0, 1),
		BorderSizePixel = 0,
		ZIndex = 80,
	}, {
		Stroke = React.createElement("UIStroke", {
			Color = theme.Semantic.danger,
			Thickness = layout.px(18),
			Transparency = alpha,
		}),
		Alert = React.createElement("Frame", {
			Size = UDim2.fromOffset(layout.px(if layout.isPhone then 280 else 360), layout.px(70)),
			Position = UDim2.fromOffset(
				layout.safeLeft + (layout.viewport.X - layout.safeLeft - layout.safeRight) / 2,
				layout.safeTop + layout.gap(80)
			),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
		}, {
			Icon = React.createElement(Icon, {
				name = "warning",
				size = 44,
				color = theme.Semantic.danger,
				position = UDim2.new(0, 0, 0.5, 0),
				anchorPoint = Vector2.new(0, 0.5),
			}),
			Text = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(54), 1, 0),
				Position = UDim2.fromOffset(layout.px(54), 0),
				BackgroundTransparency = 1,
				Text = string.upper(props.message or "RAID ALERT"),
				TextSize = layout.text(22),
				Font = theme.Font.display,
				TextColor3 = theme.Content.inverse,
				TextStrokeColor3 = theme.Semantic.danger,
				TextStrokeTransparency = 0,
				TextWrapped = true,
			}),
		}),
	})
end

return StealAlertVignette
