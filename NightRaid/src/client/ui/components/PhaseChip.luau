--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	phase: string,
	remainingSec: number,
}

local function PhaseChip(props: Props): React.ReactElement<any, any>
	local layout = useLayout()
	local accent = if props.phase == "Night"
		then theme.Colors.primary
		elseif props.phase == "Dusk"
		then theme.Colors.gold
		elseif props.phase == "Dawn"
		then theme.Colors.sell
		else theme.Colors.dockBorder

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.px(220), layout.px(36)),
		Position = UDim2.new(0.5, 0, 0, layout.safeTop + layout.gap(12)),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = theme.Colors.bg2,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		Stroke = React.createElement("UIStroke", {
			Color = accent,
			Thickness = theme.Stroke.medium,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = string.format("%s  %.0fs", string.upper(props.phase), props.remainingSec),
			TextSize = layout.text(16),
			Font = theme.Font.title,
			TextColor3 = theme.Colors.textMain,
		}),
	})
end

return PhaseChip
