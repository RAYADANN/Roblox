--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local Formatters = require(script.Parent.Parent.util.Formatters)
local Icon = require(script.Parent.Icon)

export type Props = {
	label: string,
	amount: number,
	accent: Color3?,
	layoutOrder: number?,
	pulseToken: number?,
	emphasize: boolean?,
	icon: string?,
	width: number?,
	position: UDim2?,
}

local function ResourceChip(props: Props): React.Node
	local layout = useLayout()
	local C = theme.Colors
	local accent = props.accent or C.gold
	local display = useFlipperSpring(props.amount, MotionPresets.SPRING_NUMBER)
	local scale, setScale = React.useState(1)
	local motorRef = React.useRef(nil :: any)
	local lastPulse = React.useRef(0)
	local chipW = layout.px(props.width or (if props.emphasize then theme.Design.CHIP_W + 8 else theme.Design.CHIP_W))
	local chipH = layout.px(theme.Design.CHIP_H)

	React.useEffect(function()
		local motor = Flipper.SingleMotor.new(1, false)
		motorRef.current = motor
		local conn = motor:onStep(setScale)
		motor:start()
		return function()
			conn:disconnect()
			motor:destroy()
			motorRef.current = nil
		end
	end, {})

	React.useEffect(function()
		local token = props.pulseToken or 0
		if token > 0 and token ~= lastPulse.current then
			lastPulse.current = token
			local motor = motorRef.current
			if motor then
				motor:setGoal(Flipper.Spring.new(1.1, MotionPresets.SPRING_BOUNCY))
				task.delay(0.12, function()
					if motorRef.current == motor then
						motor:setGoal(Flipper.Spring.new(1, MotionPresets.SPRING_SNAPPY))
					end
				end)
			end
		end
	end, { props.pulseToken })

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(chipW, chipH),
		Position = props.position,
		BackgroundColor3 = theme.Surface.raised,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Scale = React.createElement("UIScale", { Scale = scale }),
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Border.light,
			Thickness = theme.Stroke.thick,
		}),
		Lip = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, layout.px(4)),
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = theme.Action.neutralShadow,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		}),
		AccentBar = React.createElement("Frame", {
			Size = UDim2.new(0, theme.Stroke.accentBar, 1, -layout.gap(8)),
			Position = UDim2.new(0, layout.gap(4), 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.xs }),
		}),
		Icon = if props.icon
			then React.createElement(Icon, {
				name = props.icon,
				size = 18,
				color = accent,
				position = UDim2.new(0, layout.gap(12), 0.5, 0),
				anchorPoint = Vector2.new(0, 0.5),
				zIndex = 2,
			})
			else React.createElement("Frame", {
				Size = UDim2.fromOffset(layout.px(10), layout.px(10)),
				Position = UDim2.new(0, layout.gap(14), 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
			}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.new(1, -layout.px(32), 0, layout.px(14)),
			Position = UDim2.fromOffset(layout.px(28), layout.gap(6)),
			BackgroundTransparency = 1,
			Text = string.upper(props.label),
			TextSize = layout.text(10),
			Font = theme.Font.caption,
			TextColor3 = theme.Content.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
		}),
		Amount = React.createElement("TextLabel", {
			Size = UDim2.new(1, -layout.px(32), 0, layout.px(22)),
			Position = UDim2.fromOffset(layout.px(28), layout.px(20)),
			BackgroundTransparency = 1,
			Text = Formatters.shortNumber(math.floor(display + 0.5)),
			TextSize = layout.text(if props.emphasize then 18 else 16),
			Font = theme.Font.heavy,
			TextColor3 = theme.Content.primary,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
		}),
	})
end

return ResourceChip
