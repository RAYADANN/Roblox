--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Icon = require(script.Parent.Icon)
local Surface = require(script.Parent.Surface)
local Typography = require(script.Parent.Typography)

export type Props = {
	title: string,
	subtitle: string?,
	accent: Color3?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	onClose: (() -> ())?,
	zIndex: number?,
	children: React.Node?,
}

local function WindowShell(props: Props): React.Node
	local layout = useLayout()
	local headerHeight = layout.px(theme.Design.HEADER_H)
	local accent = props.accent or theme.Action.primary

	return React.createElement(Surface, {
		tone = "base",
		size = props.size or UDim2.fromOffset(layout.px(theme.Design.MODAL_W), layout.px(theme.Design.MODAL_H)),
		position = props.position,
		anchorPoint = props.anchorPoint,
		strokeColor = theme.Border.light,
		strokeThickness = theme.Stroke.thick,
		shadowColor = theme.Action.neutralShadow,
		zIndex = props.zIndex or 20,
		clipsDescendants = true,
	}, {
		Header = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, headerHeight),
			BackgroundColor3 = theme.Surface.tinted,
			BorderSizePixel = 0,
		}, {
			Accent = React.createElement("Frame", {
				Size = UDim2.new(0, layout.px(8), 1, -layout.gap(20)),
				Position = UDim2.fromOffset(layout.gap(12), layout.gap(10)),
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
			}),
			Title = React.createElement(Typography, {
				text = props.title,
				variant = "title",
				size = UDim2.new(1, -layout.px(100), 0, layout.px(28)),
				position = UDim2.fromOffset(layout.gap(30), layout.gap(7)),
			}),
			Subtitle = if props.subtitle
				then React.createElement(Typography, {
					text = props.subtitle,
					variant = "caption",
					size = UDim2.new(1, -layout.px(100), 0, layout.px(18)),
					position = UDim2.fromOffset(layout.gap(30), layout.gap(34)),
				})
				else nil,
			Close = if props.onClose
				then React.createElement("TextButton", {
					Size = UDim2.fromOffset(layout.touch(42), layout.touch(42)),
					Position = UDim2.new(1, -layout.gap(10), 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = theme.Action.danger,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					[React.Event.Activated] = props.onClose,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.badge }),
					Stroke = React.createElement("UIStroke", {
						Color = theme.Border.light,
						Thickness = theme.Stroke.thin,
					}),
					Icon = React.createElement(Icon, {
						name = "close",
						size = 24,
						color = theme.Content.inverse,
						position = UDim2.fromScale(0.5, 0.5),
						anchorPoint = Vector2.new(0.5, 0.5),
					}),
				})
				else nil,
		}),
		Content = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, -headerHeight),
			Position = UDim2.fromOffset(0, headerHeight),
			BackgroundTransparency = 1,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, layout.gap(theme.Space.md)),
				PaddingBottom = UDim.new(0, layout.gap(theme.Space.md)),
				PaddingLeft = UDim.new(0, layout.gap(theme.Space.md)),
				PaddingRight = UDim.new(0, layout.gap(theme.Space.md)),
			}),
			Body = props.children,
		}),
	})
end

return WindowShell
