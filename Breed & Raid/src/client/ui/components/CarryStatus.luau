--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local ProgressBar = require(script.Parent.ProgressBar)
local Surface = require(script.Parent.Surface)

export type Props = {
	text: string?,
	startedAt: number?,
}

local function CarryStatus(props: Props): React.Node
	local layout = useLayout()
	local now, setNow = React.useState(os.clock())
	React.useEffect(function()
		if not props.text then
			return
		end
		local last = 0
		local connection = RunService.Heartbeat:Connect(function()
			local current = os.clock()
			if current - last >= 1 then
				last = current
				setNow(current)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { props.text, props.startedAt })
	if not props.text then
		return nil
	end

	local elapsed = math.max(0, now - (props.startedAt or now))
	local remaining = math.max(0, 90 - elapsed)

	return React.createElement(Surface, {
		tone = "raised",
		size = UDim2.fromOffset(layout.px(if layout.isPhone then 280 else 360), layout.px(66)),
		position = UDim2.new(0.5, 0, 1, -layout.gap(if layout.isPhone then 142 else 126)),
		anchorPoint = Vector2.new(0.5, 1),
		radius = theme.Radius.chip,
		strokeColor = theme.Semantic.warning,
		zIndex = 19,
	}, {
		Label = React.createElement("TextLabel", {
			Size = UDim2.new(1, -layout.gap(20), 0, layout.px(28)),
			Position = UDim2.fromOffset(layout.gap(10), layout.gap(7)),
			BackgroundTransparency = 1,
			Text = string.upper(props.text),
			TextSize = layout.text(13),
			Font = theme.Font.heavy,
			TextColor3 = theme.Semantic.warning,
		}),
		BarHost = React.createElement("Frame", {
			Size = UDim2.new(1, -layout.gap(20), 0, layout.px(12)),
			Position = UDim2.new(0, layout.gap(10), 1, -layout.gap(18)),
			BackgroundTransparency = 1,
		}, {
			Bar = React.createElement(ProgressBar, {
				progress = remaining / 90,
				height = 12,
				accent = theme.Semantic.warning,
			}),
		}),
	})
end

return CarryStatus
