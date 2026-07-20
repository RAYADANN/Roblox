--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	battery: number, -- 0..1
}

local function BatteryBar(props: Props): React.ReactElement<any, any>
	local layout = useLayout()
	local fill = math.clamp(props.battery, 0, 1)
	local color = if fill < 0.2 then theme.Colors.error elseif fill < 0.45 then theme.Colors.gold else theme.Colors.sell

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.px(168), layout.px(18)),
		BackgroundColor3 = theme.Colors.bg3,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.dockBorder,
			Thickness = theme.Stroke.thin,
		}),
		Fill = React.createElement("Frame", {
			Size = UDim2.new(fill, 0, 1, 0),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Text = string.format("Battery %.0f%%", fill * 100),
			TextSize = layout.text(11),
			Font = theme.Font.body,
			TextColor3 = theme.Colors.textMain,
		}),
	})
end

return BatteryBar
