--!strict
-- Left vertical nav — Pets / Breed / Shop / Collect (reference layout).

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
	local top = layout.safeTop + layout.px(theme.Design.CHIP_H) + layout.gap(16)

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.touch(theme.Design.NAV_BTN) + layout.gap(8), layout.px(420)),
		Position = UDim2.fromOffset(layout.safeLeft + layout.gap(10), top),
		BackgroundTransparency = 1,
		ZIndex = 15,
	}, {
		List = React.createElement("UIListLayout", {
			Padding = UDim.new(0, layout.gap(10)),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Pets = React.createElement(SimIconButton, {
			label = "Pets",
			icon = "🐱",
			tone = "blue",
			active = props.petsActive,
			layoutOrder = 1,
			onClick = props.onPets,
		}),
		Breed = React.createElement(SimIconButton, {
			label = "Breed",
			icon = "🥚",
			tone = "orange",
			active = props.breedActive,
			layoutOrder = 2,
			onClick = props.onBreed,
		}),
		Shop = React.createElement(SimIconButton, {
			label = "Shop",
			icon = "🛒",
			tone = "red",
			active = props.shopActive,
			layoutOrder = 3,
			onClick = props.onShop,
		}),
		Collect = React.createElement(SimIconButton, {
			label = props.collectLabel or "Collect",
			icon = "💰",
			tone = "green",
			layoutOrder = 4,
			onClick = props.onCollect,
		}),
	})
end

return LeftNav
