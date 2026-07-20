--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	text: string,
	color: Color3?,
}

local function Toast(props: Props): React.ReactElement<any, any>?
	local layout = useLayout()
	if props.text == "" then
		return nil
	end

	return React.createElement("Frame", {
		Size = UDim2.new(0, layout.px(400), 0, layout.px(44)),
		Position = UDim2.new(0.5, 0, 0.75, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
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
			Text = props.text,
			TextSize = layout.text(16),
			Font = theme.Font.title,
			TextColor3 = props.color or theme.Colors.goldHi,
		}),
	})
end

return Toast
