--!strict
-- Hero "1 in X" — primary flex (GDD). Dark surface, rarity stroke.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	oneIn: number,
	rarity: string?,
	layoutOrder: number?,
	compact: boolean?,
}

local function OneInBadge(props: Props): React.Node
	local layout = useLayout()
	local band = props.rarity or "Common"
	local accent = theme.rarityColor(band)
	local compact = props.compact == true
	local h = layout.px(if compact then 28 else 44)

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = theme.Colors.bg4,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.sm }),
		Stroke = React.createElement("UIStroke", {
			Color = accent,
			Thickness = theme.Stroke.medium,
		}),
		Bar = React.createElement("Frame", {
			Size = UDim2.new(0, theme.Stroke.accentBar, 1, -layout.gap(8)),
			Position = UDim2.new(0, layout.gap(4), 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.xs }),
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.new(1, -layout.gap(12), 1, 0),
			Position = UDim2.fromOffset(layout.gap(12), 0),
			BackgroundTransparency = 1,
			Text = FormatOneIn(props.oneIn),
			TextSize = layout.text(if compact then 16 else 22),
			Font = theme.Font.display,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return OneInBadge
