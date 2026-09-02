--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Variant = "display" | "title" | "body" | "caption" | "label"
export type Props = {
	text: string,
	variant: Variant?,
	color: Color3?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
	textXAlignment: Enum.TextXAlignment?,
	textYAlignment: Enum.TextYAlignment?,
	textWrapped: boolean?,
	textTruncate: Enum.TextTruncate?,
}

local function style(variant: Variant): (Enum.Font, number, Color3)
	if variant == "display" then
		return theme.Font.display, 28, theme.Content.primary
	elseif variant == "title" then
		return theme.Font.title, 20, theme.Content.primary
	elseif variant == "caption" then
		return theme.Font.caption, 12, theme.Content.muted
	elseif variant == "label" then
		return theme.Font.heavy, 13, theme.Content.secondary
	end
	return theme.Font.body, 15, theme.Content.secondary
end

local function Typography(props: Props): React.Node
	local layout = useLayout()
	local font, textSize, defaultColor = style(props.variant or "body")

	return React.createElement("TextLabel", {
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		Text = props.text,
		TextSize = layout.text(textSize),
		Font = font,
		TextColor3 = props.color or defaultColor,
		TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.textYAlignment or Enum.TextYAlignment.Center,
		TextWrapped = props.textWrapped == true,
		TextTruncate = props.textTruncate,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
	})
end

return Typography
