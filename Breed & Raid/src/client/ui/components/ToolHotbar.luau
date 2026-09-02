--!strict
-- Minimal edge tool dock — build and defense only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local SimIconButton = require(script.Parent.SimIconButton)

export type Props = {
	buildActive: boolean?,
	batActive: boolean?,
	onHammer: () -> (),
	onBat: () -> (),
}

local function ToolHotbar(props: Props): React.Node
	local layout = useLayout()
	local buttonSize = if layout.isPhone then 58 else 66
	local slot = layout.touch(buttonSize)
	local gap = layout.gap(10)
	local pad = layout.gap(10)
	local w = slot * 2 + gap + pad * 2
	local h = slot + pad * 2

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.new(0.5, 0, 1, -(h + layout.gap(if layout.isPhone then 22 else 14))),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = theme.Surface.base,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.lg }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Border.light,
			Thickness = theme.Stroke.medium,
		}),
		Pad = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, pad),
			PaddingBottom = UDim.new(0, pad),
			PaddingLeft = UDim.new(0, pad),
			PaddingRight = UDim.new(0, pad),
		}),
		List = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, gap),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Hammer = React.createElement(SimIconButton, {
			label = "Build",
			icon = "",
			iconName = "build",
			tone = "cyan",
			active = props.buildActive,
			size = buttonSize,
			showLabel = false,
			layoutOrder = 1,
			onClick = props.onHammer,
		}),
		Bat = React.createElement(SimIconButton, {
			label = "Bat",
			icon = "",
			iconName = "bat",
			tone = "red",
			active = props.batActive,
			size = buttonSize,
			showLabel = false,
			layoutOrder = 2,
			onClick = props.onBat,
		}),
	})
end

return ToolHotbar
