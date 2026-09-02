--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Tone = "neutral" | "info" | "success" | "warning" | "danger"
export type Props = {
	text: string,
	tone: Tone?,
	dot: boolean?,
	layoutOrder: number?,
}

local function toneColor(tone: Tone): Color3
	if tone == "info" then
		return theme.Semantic.info
	elseif tone == "success" then
		return theme.Semantic.success
	elseif tone == "warning" then
		return theme.Semantic.warning
	elseif tone == "danger" then
		return theme.Semantic.danger
	end
	return theme.Action.neutral
end

local function StatusChip(props: Props): React.Node
	local layout = useLayout()
	local accent = toneColor(props.tone or "neutral")
	local showDot = props.dot ~= false

	return React.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, layout.px(30)),
		BackgroundColor3 = theme.Surface.raised,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
		Stroke = React.createElement("UIStroke", {
			Color = accent,
			Thickness = theme.Stroke.thin,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, layout.gap(if showDot then 9 else 12)),
			PaddingRight = UDim.new(0, layout.gap(12)),
		}),
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, layout.gap(6)),
		}),
		Dot = if showDot
			then React.createElement("Frame", {
				Size = UDim2.fromOffset(layout.px(9), layout.px(9)),
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
			})
			else nil,
		Label = React.createElement("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = string.upper(props.text),
			TextSize = layout.text(11),
			Font = theme.Font.heavy,
			TextColor3 = accent,
		}),
	})
end

return StatusChip
