--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.theme)
local useLayout = require(script.Parent.hooks.useLayout)

export type ToastItem = {
	id: string,
	text: string,
	color: Color3?,
}

export type Props = {
	item: ToastItem,
}

local function Toast(props: Props): React.Node
	local layout = useLayout()
	local color = props.item.color or theme.Colors.textMain

	return React.createElement("Frame", {
		Size = UDim2.new(0.8, 0, 0, layout.px(44)),
		BackgroundColor3 = theme.Colors.bg3,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.dockBorder,
			Thickness = theme.Stroke.thin,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = props.item.text,
			TextSize = layout.text(14),
			Font = theme.Font.body,
			TextColor3 = color,
		}),
	})
end

return Toast
