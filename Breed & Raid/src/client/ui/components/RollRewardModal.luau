--!strict
-- R3 center reward / shop popup — replaces always-on SUMMON rail.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local HudContext = require(script.Parent.Parent.context.HudContext)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local PanelChrome = require(script.Parent.PanelChrome)
local OrnateButton = require(script.Parent.OrnateButton)
local OneInBadge = require(script.Parent.OneInBadge)

export type Props = {
	open: boolean,
	onClose: () -> (),
}

local function RollRewardModal(props: Props): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	if not props.open then
		return React.createElement(React.Fragment)
	end

	local preview = ctx.hud.creaturePreview
	local block = ctx.hud.blockPreview
	local C = theme.Colors
	local rarity = if preview then theme.rarityColor(preview.rarity) else C.outlineSoft
	local cardW = layout.px(theme.Design.REWARD_W)
	local cardH = layout.px(theme.Design.REWARD_H)
	local btnW = theme.Design.REWARD_W - theme.Design.PAD_MD * 2

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.veil,
		BackgroundTransparency = 0.35,
		ZIndex = 25,
	}, {
		HitClose = React.createElement("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 25,
			[React.Event.Activated] = props.onClose,
		}),
		CardWrap = React.createElement("Frame", {
			Size = UDim2.fromOffset(cardW, cardH),
			Position = UDim2.fromScale(0.5, 0.48),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = 26,
		}, {
			Card = React.createElement(PanelChrome, {
				title = "SHOP",
				subtitle = if preview then preview.rarity else "Roll & buy",
				size = UDim2.fromScale(1, 1),
				zIndex = 26,
				children = React.createElement("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
				}, {
				List = React.createElement("UIListLayout", {
					Padding = UDim.new(0, layout.gap(10)),
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
				Egg = React.createElement("Frame", {
					Size = UDim2.fromOffset(layout.px(88), layout.px(88)),
					BackgroundColor3 = C.bg4,
					BorderSizePixel = 0,
					LayoutOrder = 1,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
					Stroke = React.createElement("UIStroke", {
						Color = rarity,
						Thickness = theme.Stroke.medium,
					}),
					Glyph = React.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = if preview then "★" else "?",
						TextSize = layout.text(36),
						Font = theme.Font.display,
						TextColor3 = if preview then rarity else C.textMuted,
					}),
				}),
				Name = React.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, layout.px(20)),
					BackgroundTransparency = 1,
					Text = if preview then preview.displayName else "No preview yet",
					TextSize = layout.text(16),
					Font = theme.Font.title,
					TextColor3 = C.textMain,
					LayoutOrder = 2,
				}),
				Odds = if preview
					then React.createElement(OneInBadge, {
						oneIn = preview.oneIn,
						rarity = preview.rarity,
						layoutOrder = 3,
					})
					else React.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, layout.px(36)),
						BackgroundTransparency = 1,
						Text = "Roll at the pad or tap below",
						TextSize = layout.text(14),
						Font = theme.Font.body,
						TextColor3 = C.textMuted,
						LayoutOrder = 3,
					}),
				Meta = React.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, layout.px(16)),
					BackgroundTransparency = 1,
					Text = if preview
						then `${preview.buyCost}  ·  {preview.mps or 0}/s`
						else "Free preview · buy to keep",
					TextSize = layout.text(12),
					Font = theme.Font.body,
					TextColor3 = C.textSub,
					LayoutOrder = 4,
				}),
				Primary = if preview
					then React.createElement(OrnateButton, {
						text = `Buy  ·  ${preview.buyCost}`,
						variant = "gold",
						onClick = ctx.confirmCreatureBuy,
						width = btnW,
						height = 44,
						layoutOrder = 5,
						disabled = ctx.hud.cash < preview.buyCost,
					})
					else React.createElement(OrnateButton, {
						text = "Roll Creature",
						variant = "jade",
						onClick = ctx.requestCreatureRoll,
						width = btnW,
						height = 44,
						layoutOrder = 5,
					}),
				Again = if preview
					then React.createElement(OrnateButton, {
						text = "Roll Again",
						variant = "ghost",
						onClick = ctx.requestCreatureRoll,
						width = btnW,
						height = 36,
						layoutOrder = 6,
					})
					else nil,
				Divider = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = C.outlineSoft,
					BackgroundTransparency = 0.4,
					BorderSizePixel = 0,
					LayoutOrder = 7,
				}),
				BlockInfo = React.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, layout.px(16)),
					BackgroundTransparency = 1,
					Text = if block
						then `{block.displayName} · {FormatOneIn(block.oneIn)} · ${block.buyCost}`
						else `Blocks · Dirt {ctx.hud.dirt} · Spikes {ctx.hud.spikes}`,
					TextSize = layout.text(11),
					Font = theme.Font.body,
					TextColor3 = C.textMuted,
					TextTruncate = Enum.TextTruncate.AtEnd,
					LayoutOrder = 8,
				}),
				BlockRow = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, layout.px(36)),
					BackgroundTransparency = 1,
					LayoutOrder = 9,
				}, {
					List = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, layout.gap(8)),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),
					Roll = React.createElement(OrnateButton, {
						text = "Roll Blocks",
						variant = "ghost",
						onClick = ctx.requestBlockRoll,
						width = 130,
						height = 34,
						layoutOrder = 1,
					}),
					Buy = React.createElement(OrnateButton, {
						text = if block then `Buy +{block.grantQty or 100}` else "Buy Pack",
						variant = "gold",
						onClick = ctx.confirmBlockBuy,
						width = 130,
						height = 34,
						disabled = block == nil or ctx.hud.cash < (block and block.buyCost or math.huge),
						layoutOrder = 2,
					}),
				}),
				Close = React.createElement(OrnateButton, {
					text = "Close",
					variant = "ghost",
					onClick = props.onClose,
					width = 120,
					height = 34,
					layoutOrder = 10,
				}),
			}),
			}),
		}),
	})
end

return RollRewardModal
