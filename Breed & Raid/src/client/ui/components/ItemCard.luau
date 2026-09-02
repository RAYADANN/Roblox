--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local Badge = require(script.Parent.Badge)
local Icon = require(script.Parent.Icon)
local Shadow = require(script.Parent.Shadow)
local Typography = require(script.Parent.Typography)

export type Props = {
	title: string,
	subtitle: string?,
	icon: string?,
	image: string?,
	accent: Color3?,
	badge: string?,
	selected: boolean?,
	disabled: boolean?,
	width: number?,
	height: number?,
	layoutOrder: number?,
	onClick: (() -> ())?,
	footer: React.Node?,
}

local function ItemCard(props: Props): React.Node
	local layout = useLayout()
	local accent = props.accent or theme.Action.primary
	local disabled = props.disabled == true
	local scale, handlers = useHoverPress({ disabled = disabled or props.onClick == nil })
	local width = layout.px(props.width or theme.Design.CARD_W)
	local height = layout.px(props.height or theme.Design.CARD_H)

	return React.createElement("TextButton", {
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Active = props.onClick ~= nil and not disabled,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = function()
			if not disabled and props.onClick then
				props.onClick()
			end
		end,
		[React.Event.MouseEnter] = handlers.onMouseEnter,
		[React.Event.MouseLeave] = handlers.onMouseLeave,
		[React.Event.MouseButton1Down] = handlers.onMouseDown,
		[React.Event.MouseButton1Up] = handlers.onMouseUp,
	}, {
		Scale = React.createElement("UIScale", { Scale = scale }),
		Shadow = React.createElement(Shadow, {
			color = if props.selected then accent else theme.Action.neutralShadow,
			radius = theme.Radius.lg,
		}),
		Face = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.Surface.raised,
			BackgroundTransparency = if disabled then theme.Opacity.disabled else 0,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.lg }),
			Stroke = React.createElement("UIStroke", {
				Color = if props.selected then accent else theme.Border.light,
				Thickness = if props.selected then theme.Stroke.thick else theme.Stroke.medium,
			}),
			Art = React.createElement("Frame", {
				Size = UDim2.new(1, -layout.gap(16), 0, layout.px(112)),
				Position = UDim2.fromOffset(layout.gap(8), layout.gap(8)),
				BackgroundColor3 = theme.Surface.tinted,
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.md }),
				Image = if props.image
					then React.createElement("ImageLabel", {
						Size = UDim2.new(1, -layout.gap(18), 1, -layout.gap(18)),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Image = props.image,
						ScaleType = Enum.ScaleType.Fit,
					})
					else React.createElement(Icon, {
						name = props.icon or "sparkle",
						size = 56,
						color = accent,
						position = UDim2.fromScale(0.5, 0.5),
						anchorPoint = Vector2.new(0.5, 0.5),
					}),
			}),
			Badge = if props.badge
				then React.createElement(Badge, {
					text = props.badge,
					accent = accent,
					width = 76,
					position = UDim2.new(1, -layout.gap(8), 0, layout.gap(8)),
					anchorPoint = Vector2.new(1, 0),
					zIndex = 4,
				})
				else nil,
			Title = React.createElement(Typography, {
				text = props.title,
				variant = "title",
				size = UDim2.new(1, -layout.gap(16), 0, layout.px(26)),
				position = UDim2.fromOffset(layout.gap(8), layout.px(126)),
				textXAlignment = Enum.TextXAlignment.Center,
				textTruncate = Enum.TextTruncate.AtEnd,
			}),
			Subtitle = if props.subtitle
				then React.createElement(Typography, {
					text = props.subtitle,
					variant = "caption",
					size = UDim2.new(1, -layout.gap(16), 0, layout.px(20)),
					position = UDim2.fromOffset(layout.gap(8), layout.px(154)),
					textXAlignment = Enum.TextXAlignment.Center,
					textTruncate = Enum.TextTruncate.AtEnd,
				})
				else nil,
			Footer = if props.footer
				then React.createElement("Frame", {
					Size = UDim2.new(1, -layout.gap(16), 0, layout.px(30)),
					Position = UDim2.new(0, layout.gap(8), 1, -layout.gap(36)),
					BackgroundTransparency = 1,
				}, {
					Content = props.footer,
				})
				else nil,
		}),
	})
end

return ItemCard
