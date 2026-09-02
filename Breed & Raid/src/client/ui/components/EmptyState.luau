--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Icon = require(script.Parent.Icon)
local Typography = require(script.Parent.Typography)

export type Props = {
	title: string,
	description: string?,
	icon: string?,
	accent: Color3?,
	layoutOrder: number?,
}

local function EmptyState(props: Props): React.Node
	local layout = useLayout()
	local accent = props.accent or theme.Action.primary

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		IconWell = React.createElement("Frame", {
			Size = UDim2.fromOffset(layout.px(82), layout.px(82)),
			Position = UDim2.new(0.5, 0, 0.5, -layout.px(38)),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = theme.Surface.tinted,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.lg }),
			Stroke = React.createElement("UIStroke", {
				Color = accent,
				Thickness = theme.Stroke.medium,
			}),
			Icon = React.createElement(Icon, {
				name = props.icon or "empty",
				size = 44,
				color = accent,
				position = UDim2.fromScale(0.5, 0.5),
				anchorPoint = Vector2.new(0.5, 0.5),
			}),
		}),
		Title = React.createElement(Typography, {
			text = props.title,
			variant = "title",
			size = UDim2.new(0.8, 0, 0, layout.px(28)),
			position = UDim2.new(0.5, 0, 0.5, -layout.px(26)),
			anchorPoint = Vector2.new(0.5, 0),
			textXAlignment = Enum.TextXAlignment.Center,
		}),
		Description = if props.description
			then React.createElement(Typography, {
				text = props.description,
				variant = "body",
				size = UDim2.new(0.78, 0, 0, layout.px(48)),
				position = UDim2.new(0.5, 0, 0.5, layout.px(4)),
				anchorPoint = Vector2.new(0.5, 0),
				textXAlignment = Enum.TextXAlignment.Center,
				textWrapped = true,
			})
			else nil,
	})
end

return EmptyState
