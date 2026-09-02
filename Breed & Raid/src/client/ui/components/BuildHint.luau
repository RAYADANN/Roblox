--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Icon = require(script.Parent.Icon)
local Surface = require(script.Parent.Surface)

export type Props = {
	blockName: string,
	visible: boolean?,
}

local function BuildHint(props: Props): React.Node
	local layout = useLayout()
	if props.visible == false then
		return nil
	end

	return React.createElement(Surface, {
		tone = "raised",
		size = UDim2.fromOffset(layout.px(if layout.isPhone then 300 else 430), layout.px(42)),
		position = UDim2.new(0.5, 0, 1, -layout.gap(if layout.isPhone then 128 else 116)),
		anchorPoint = Vector2.new(0.5, 1),
		radius = theme.Radius.chip,
		strokeColor = theme.Action.primary,
		zIndex = 18,
	}, {
		Icon = React.createElement(Icon, {
			name = "build",
			size = 22,
			color = theme.Action.primary,
			position = UDim2.new(0, layout.gap(12), 0.5, 0),
			anchorPoint = Vector2.new(0, 0.5),
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.new(1, -layout.px(48), 1, 0),
			Position = UDim2.fromOffset(layout.px(42), 0),
			BackgroundTransparency = 1,
			Text = if layout.isPhone
				then `{string.upper(props.blockName)} · tap place · use Take prompt to break`
				else `{string.upper(props.blockName)} · Q cycle · click place · Shift+click break`,
			TextSize = layout.text(11),
			Font = theme.Font.heavy,
			TextColor3 = theme.Content.primary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})
end

return BuildHint
