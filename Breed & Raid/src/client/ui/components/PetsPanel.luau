--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.Parent.context.HudContext)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local EmptyState = require(script.Parent.EmptyState)
local ItemCard = require(script.Parent.ItemCard)
local Modal = require(script.Parent.Modal)
local OneInBadge = require(script.Parent.OneInBadge)
local OrnateButton = require(script.Parent.OrnateButton)

export type Props = {
	open: boolean,
	onClose: () -> (),
	onBreed: () -> (),
}

local function PetsPanel(props: Props): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	local cardWidth = if layout.isPhone then 142 else 168
	local cardHeight = if layout.isPhone then 194 else 214
	local cards: { [string]: React.Node } = {
		Grid = React.createElement("UIGridLayout", {
			CellSize = UDim2.fromOffset(layout.px(cardWidth), layout.px(cardHeight)),
			CellPadding = UDim2.fromOffset(layout.gap(10), layout.gap(10)),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	}

	for index, creature in ctx.hud.creatures do
		cards[`Creature{index}`] = React.createElement(ItemCard, {
			title = creature.displayName,
			subtitle = `${creature.mps}/s · {creature.nestId or "storage"}`,
			icon = "pets",
			accent = theme.rarityColor(creature.rarity),
			badge = if creature.isHybrid then "HYBRID" else creature.rarity,
			width = cardWidth,
			height = cardHeight,
			layoutOrder = index,
			footer = React.createElement(OneInBadge, {
				oneIn = creature.oneIn,
				rarity = creature.rarity,
				compact = true,
			}),
		})
	end

	return React.createElement(Modal, {
		visible = props.open,
		title = "CREATURES",
		subtitle = `{#ctx.hud.creatures} owned · one-in is the flex`,
		accent = theme.Action.primary,
		width = 560,
		height = 560,
		onClose = props.onClose,
		zIndex = 25,
	}, React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Content = if #ctx.hud.creatures == 0
			then React.createElement(EmptyState, {
				title = "No creatures yet",
				description = "Open Roll Shop and reveal your first creature.",
				icon = "pets",
				accent = theme.Action.primary,
			})
			else React.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -layout.px(70)),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 5,
				ScrollBarImageColor3 = theme.Action.primary,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromOffset(0, 0),
			}, cards),
		Breed = React.createElement(OrnateButton, {
			text = "OPEN FUSE",
			variant = "primary",
			icon = "breed",
			width = 220,
			position = UDim2.new(0.5, 0, 1, -layout.gap(6)),
			anchorPoint = Vector2.new(0.5, 1),
			onClick = props.onBreed,
			disabled = #ctx.hud.creatures < 2,
		}),
	}))
end

return PetsPanel
