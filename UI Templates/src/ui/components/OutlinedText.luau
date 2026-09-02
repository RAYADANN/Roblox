--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Gradient = require(script.Parent.Parent.util.Gradient)
local theme = require(script.Parent.Parent.theme)
local usePulse = require(script.Parent.Parent.hooks.usePulse)

export type Props = {
	text: string,
	size: UDim2,
	variant: "title" | "body" | "count"?,
	layoutOrder: number?,
	pulse: boolean?,
	position: UDim2?,
	anchorPoint: Vector2?,
	textXAlignment: Enum.TextXAlignment?,
	zIndex: number?,
}

local function OutlinedText(props: Props): React.Node
	local variant = props.variant or "body"
	local stroke = if variant == "title" then theme.Stroke.title else theme.Stroke.text
	local pulseEnabled = if props.pulse ~= nil then props.pulse else variant == "count"
	local pulseScale = usePulse({
		enabled = pulseEnabled,
		minScale = 1,
		maxScale = 1.08,
		frequency = 2.4,
	})

	local children: { [string]: React.Node } = {
		PulseScale = React.createElement("UIScale", { Scale = pulseScale }),
		Outline = React.createElement("UIStroke", {
			Color = theme.Colors.black,
			Thickness = stroke,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}),
		TextSizeConstraint = React.createElement("UITextSizeConstraint", {
			MinTextSize = 10,
			MaxTextSize = 96,
		}),
	}
	if variant == "count" then
		children.Gradient = Gradient.element({
			rotation = 90,
			stops = {
				{ pos = 0, color = theme.Colors.countLight, alpha = 0.25 },
				{ pos = 0.34, color = theme.Colors.countWarm, alpha = 1 },
				{ pos = 1, color = theme.Colors.countWarm, alpha = 1 },
			},
		})
	end

	return React.createElement("TextLabel", {
		Size = props.size,
		Position = props.position,
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		AutomaticSize = if props.size.X.Scale == 0 and props.size.X.Offset == 0
			then Enum.AutomaticSize.X
			else Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		Text = props.text,
		Font = theme.Font.display,
		TextScaled = true,
		TextColor3 = theme.Colors.white,
		TextStrokeTransparency = 1,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Left,
	}, children)
end

return OutlinedText
