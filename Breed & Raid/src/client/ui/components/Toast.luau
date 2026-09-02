--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Icon = require(script.Parent.Icon)
local Surface = require(script.Parent.Surface)
local Typography = require(script.Parent.Typography)

export type Tone = "info" | "success" | "warning" | "danger"
export type Props = {
	text: string,
	title: string?,
	tone: Tone?,
	icon: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
}

local function toneColor(tone: Tone): Color3
	if tone == "success" then
		return theme.Semantic.success
	elseif tone == "warning" then
		return theme.Semantic.warning
	elseif tone == "danger" then
		return theme.Semantic.danger
	end
	return theme.Semantic.info
end

local function Toast(props: Props): React.Node
	local layout = useLayout()
	local tone = props.tone or "info"
	local accent = toneColor(tone)

	return React.createElement(Surface, {
		tone = "raised",
		size = props.size or UDim2.fromOffset(layout.px(theme.Design.TOAST_W), layout.px(theme.Design.TOAST_H)),
		position = props.position,
		anchorPoint = props.anchorPoint,
		layoutOrder = props.layoutOrder,
		zIndex = props.zIndex or 50,
		radius = theme.Radius.chip,
		shadowColor = accent,
	}, {
		Accent = React.createElement("Frame", {
			Size = UDim2.new(0, layout.px(7), 1, -layout.gap(12)),
			Position = UDim2.fromOffset(layout.gap(6), layout.gap(6)),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
		}),
		Icon = React.createElement(Icon, {
			name = props.icon or tone,
			size = 28,
			color = accent,
			position = UDim2.new(0, layout.gap(20), 0.5, 0),
			anchorPoint = Vector2.new(0, 0.5),
		}),
		Title = if props.title
			then React.createElement(Typography, {
				text = props.title,
				variant = "label",
				size = UDim2.new(1, -layout.px(66), 0, layout.px(20)),
				position = UDim2.fromOffset(layout.gap(58), layout.gap(9)),
			})
			else nil,
		Message = React.createElement(Typography, {
			text = props.text,
			variant = if props.title then "caption" else "body",
			size = UDim2.new(1, -layout.px(66), 0, layout.px(if props.title then 24 else 44)),
			position = UDim2.fromOffset(layout.gap(58), layout.gap(if props.title then 29 else 10)),
			textWrapped = true,
		}),
	})
end

return Toast
