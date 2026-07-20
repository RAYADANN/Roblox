--!strict
-- Bottom tool hotbar — Hammer (build) + Bat (combat). Inventory tools only.

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
	local slot = layout.touch(theme.Design.HOTBAR_BTN)
	local gap = layout.gap(12)
	local pad = layout.gap(14)
	local w = slot * 2 + gap + pad * 2
	local h = slot + pad * 2 + layout.px(8)

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.new(0.5, 0, 1, -(h + layout.gap(14))),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(25, 28, 40),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.lg }),
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
			Transparency = 0.75,
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
			icon = "🔨",
			tone = "cyan",
			active = props.buildActive,
			size = theme.Design.HOTBAR_BTN,
			layoutOrder = 1,
			onClick = props.onHammer,
		}),
		Bat = React.createElement(SimIconButton, {
			label = "Bat",
			icon = "🏏",
			tone = "wood",
			active = props.batActive,
			size = theme.Design.HOTBAR_BTN,
			layoutOrder = 2,
			onClick = props.onBat,
		}),
	})
end

return ToolHotbar
