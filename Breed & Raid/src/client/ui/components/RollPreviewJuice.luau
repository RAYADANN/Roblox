--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)

local theme = require(script.Parent.Parent.theme)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)

export type Props = {
	token: number,
}

local function RollPreviewJuice(props: Props): React.Node
	local scale, setScale = React.useState(0)
	local visible, setVisible = React.useState(false)

	React.useEffect(function()
		if props.token <= 0 then
			return
		end
		setVisible(true)
		local motor = Flipper.SingleMotor.new(0.6, false)
		local connection = motor:onStep(setScale)
		motor:start()
		motor:setGoal(Flipper.Spring.new(1.25, MotionPresets.Spring.bouncy))
		local settle = task.delay(0.16, function()
			motor:setGoal(Flipper.Spring.new(1, MotionPresets.Spring.snappy))
		end)
		local hide = task.delay(0.7, function()
			setVisible(false)
		end)
		return function()
			pcall(task.cancel, settle)
			pcall(task.cancel, hide)
			connection:disconnect()
			motor:destroy()
		end
	end, { props.token })

	if not visible then
		return nil
	end

	return React.createElement("TextLabel", {
		Size = UDim2.fromOffset(220, 44),
		Position = UDim2.fromScale(0.5, 0.2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "NEW ROLL!",
		TextSize = 26,
		Font = theme.Font.display,
		TextColor3 = theme.Action.reward,
		TextStrokeColor3 = theme.Action.rewardShadow,
		TextStrokeTransparency = 0,
		ZIndex = 90,
	}, {
		Scale = React.createElement("UIScale", { Scale = scale }),
	})
end

return RollPreviewJuice
