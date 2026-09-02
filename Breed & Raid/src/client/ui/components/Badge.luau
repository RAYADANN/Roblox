--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	text: string,
	accent: Color3?,
	textColor: Color3?,
	width: number?,
	height: number?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
}

local function Badge(props: Props): React.Node
	local layout = useLayout()
	local accent = props.accent or theme.Action.primary

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.px(props.width or 88), layout.px(props.height or 26)),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Border.light,
			Thickness = theme.Stroke.thin,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = string.upper(props.text),
			TextSize = layout.text(11),
			Font = theme.Font.heavy,
			TextColor3 = props.textColor or theme.Content.inverse,
		}),
	})
end

return Badge
