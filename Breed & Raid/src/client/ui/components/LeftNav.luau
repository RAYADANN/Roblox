--!strict
-- Floating icon-first action dock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local SimIconButton = require(script.Parent.SimIconButton)

export type Props = {
	petsActive: boolean?,
	breedActive: boolean?,
	shopActive: boolean?,
	onPets: () -> (),
	onBreed: () -> (),
	onShop: () -> (),
	onCollect: () -> (),
	collectLabel: string?,
}

local function LeftNav(props: Props): React.Node
	local layout = useLayout()
	local buttonSize = if layout.isPhone then 54 else 64
	local dockHeight = layout.px(if layout.isPhone then 256 else 380)
	local top = layout.safeTop + layout.px(if layout.isPhone then 76 else 82)

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.touch(buttonSize) + layout.gap(12), dockHeight),
		Position = UDim2.fromOffset(layout.safeLeft + layout.gap(8), top),
		BackgroundColor3 = theme.Surface.base,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.lg }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Border.light,
			Thickness = theme.Stroke.medium,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, layout.gap(8)),
			PaddingBottom = UDim.new(0, layout.gap(8)),
			PaddingLeft = UDim.new(0, layout.gap(6)),
			PaddingRight = UDim.new(0, layout.gap(6)),
		}),
		List = React.createElement("UIListLayout", {
			Padding = UDim.new(0, layout.gap(if layout.isPhone then 6 else 8)),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Pets = React.createElement(SimIconButton, {
			label = "Pets",
			icon = "",
			iconName = "pets",
			tone = "blue",
			active = props.petsActive,
			size = buttonSize,
			showLabel = not layout.isPhone,
			layoutOrder = 1,
			onClick = props.onPets,
		}),
		Breed = React.createElement(SimIconButton, {
			label = "Breed",
			icon = "",
			iconName = "breed",
			tone = "purple",
			active = props.breedActive,
			size = buttonSize,
			showLabel = not layout.isPhone,
			layoutOrder = 2,
			onClick = props.onBreed,
		}),
		Shop = React.createElement(SimIconButton, {
			label = "Shop",
			icon = "",
			iconName = "shop",
			tone = "orange",
			active = props.shopActive,
			size = buttonSize,
			showLabel = not layout.isPhone,
			layoutOrder = 3,
			onClick = props.onShop,
		}),
		Collect = React.createElement(SimIconButton, {
			label = props.collectLabel or "Collect",
			icon = "",
			iconName = "collect",
			tone = "green",
			size = buttonSize,
			showLabel = not layout.isPhone,
			layoutOrder = 4,
			onClick = props.onCollect,
		}),
	})
end

return LeftNav
