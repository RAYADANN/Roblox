--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local HudContext = require(script.Parent.Parent.context.HudContext)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Badge = require(script.Parent.Badge)
local Divider = require(script.Parent.Divider)
local EmptyState = require(script.Parent.EmptyState)
local ItemCard = require(script.Parent.ItemCard)
local Modal = require(script.Parent.Modal)
local OneInBadge = require(script.Parent.OneInBadge)
local OrnateButton = require(script.Parent.OrnateButton)

export type Props = {
	open: boolean,
	onClose: () -> (),
}

local function RollRewardModal(props: Props): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	local preview = ctx.hud.creaturePreview
	local block = ctx.hud.blockPreview
	local cardWidth = if layout.isPhone then 142 else 168

	return React.createElement(Modal, {
		visible = props.open,
		title = "ROLL SHOP",
		subtitle = "Preview free · buy to keep",
		accent = theme.Action.reward,
		width = 500,
		height = 540,
		onClose = props.onClose,
		zIndex = 30,
	}, React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Preview = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, layout.px(262)),
			BackgroundTransparency = 1,
		}, {
			Card = if preview
				then React.createElement(ItemCard, {
					title = preview.displayName,
					subtitle = `${preview.mps or 0}/s`,
					icon = "pets",
					accent = theme.rarityColor(preview.rarity),
					badge = preview.rarity,
					width = cardWidth,
					height = 222,
					footer = React.createElement(OneInBadge, {
						oneIn = preview.oneIn,
						rarity = preview.rarity,
						compact = true,
					}),
				})
				else React.createElement(EmptyState, {
					title = "Ready to roll",
					description = "Reveal a creature preview for free.",
					icon = "roll",
					accent = theme.Action.reward,
				}),
			Actions = React.createElement("Frame", {
				Size = UDim2.fromOffset(layout.px(236), layout.px(152)),
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
			}, {
				List = React.createElement("UIListLayout", {
					Padding = UDim.new(0, layout.gap(10)),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Odds = if preview
					then React.createElement(OneInBadge, {
						oneIn = preview.oneIn,
						rarity = preview.rarity,
						layoutOrder = 1,
					})
					else nil,
				Buy = if preview
					then React.createElement(OrnateButton, {
						text = `BUY · ${preview.buyCost}`,
						variant = "gold",
						icon = "cash",
						width = 220,
						onClick = ctx.confirmCreatureBuy,
						disabled = ctx.hud.cash < preview.buyCost,
						layoutOrder = 2,
					})
					else React.createElement(OrnateButton, {
						text = "ROLL CREATURE",
						variant = "gold",
						icon = "roll",
						width = 220,
						onClick = ctx.requestCreatureRoll,
						layoutOrder = 2,
					}),
				Again = if preview
					then React.createElement(OrnateButton, {
						text = "Roll again",
						variant = "ghost",
						icon = "roll",
						width = 180,
						height = 40,
						onClick = ctx.requestCreatureRoll,
						layoutOrder = 3,
					})
					else nil,
			}),
		}),
		Rule = React.createElement(Divider, {
			position = UDim2.fromOffset(0, layout.px(268)),
		}),
		Block = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, layout.px(150)),
			Position = UDim2.fromOffset(0, layout.px(286)),
			BackgroundTransparency = 1,
		}, {
			Badge = React.createElement(Badge, {
				text = "BLOCK PACK · +100",
				accent = theme.Action.primary,
				width = 152,
			}),
			Info = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, layout.px(42)),
				Position = UDim2.fromOffset(0, layout.px(34)),
				BackgroundTransparency = 1,
				Text = if block
					then `{block.displayName}  ·  {FormatOneIn(block.oneIn)}  ·  ${block.buyCost}`
					else `Dirt {ctx.hud.dirt}  ·  Spikes {ctx.hud.spikes}`,
				TextSize = layout.text(15),
				Font = theme.Font.heavy,
				TextColor3 = if block then theme.rarityColor(block.rarity) else theme.Content.secondary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			Buttons = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, layout.px(54)),
				Position = UDim2.fromOffset(0, layout.px(86)),
				BackgroundTransparency = 1,
			}, {
				List = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, layout.gap(12)),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
				Roll = React.createElement(OrnateButton, {
					text = "ROLL BLOCK",
					variant = "primary",
					icon = "block",
					width = 190,
					onClick = ctx.requestBlockRoll,
				}),
				Buy = React.createElement(OrnateButton, {
					text = if block then `BUY +{block.grantQty or 100}` else "BUY PACK",
					variant = "gold",
					icon = "cash",
					width = 190,
					onClick = ctx.confirmBlockBuy,
					disabled = block == nil or ctx.hud.cash < (if block then block.buyCost else math.huge),
				}),
			}),
		}),
	}))
end

return RollRewardModal
