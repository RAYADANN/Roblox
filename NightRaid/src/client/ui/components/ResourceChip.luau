--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local Formatters = require(script.Parent.Parent.util.Formatters)

export type Props = {
	amount: number,
	label: string?,
	accent: Color3?,
	layoutOrder: number?,
}

local function ResourceChip(props: Props): React.ReactElement<any, any>
	local layout = useLayout()
	local display = useFlipperSpring(props.amount, MotionPresets.SPRING_NUMBER)
	local accent = props.accent or theme.Colors.gold
	local label = props.label or ""

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.px(168), layout.px(40)),
		BackgroundColor3 = theme.Colors.bgChip,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.dockBorder,
			Thickness = theme.Stroke.medium,
		}),
		Bar = React.createElement("Frame", {
			Size = UDim2.new(0, layout.px(3), 1, -layout.gap(10)),
			Position = UDim2.new(0, layout.gap(8), 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}),
		Amount = React.createElement("TextLabel", {
			Size = UDim2.new(1, -layout.px(20), 1, 0),
			Position = UDim2.new(0, layout.px(18), 0, 0),
			BackgroundTransparency = 1,
			Text = if label ~= ""
				then `{label} {Formatters.shortNumber(math.floor(display + 0.5))}`
				else Formatters.shortNumber(math.floor(display + 0.5)),
			TextSize = layout.text(16),
			Font = theme.Font.title,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return ResourceChip
