--!strict
-- R3 Pets panel — owned creatures list (odds hero per row).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local HudContext = require(script.Parent.Parent.context.HudContext)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local PanelChrome = require(script.Parent.PanelChrome)
local OrnateButton = require(script.Parent.OrnateButton)

export type Props = {
	open: boolean,
	onClose: () -> (),
	onBreed: () -> (),
}

local function PetsPanel(props: Props): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	if not props.open then
		return React.createElement(React.Fragment)
	end

	local C = theme.Colors
	local rows = {}
	for i, creature in ctx.hud.creatures do
		local band = theme.rarityColor(creature.rarity)
		rows["c" .. i] = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, layout.px(48)),
			BackgroundColor3 = C.bg4,
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.sm }),
			Stroke = React.createElement("UIStroke", {
				Color = band,
				Thickness = theme.Stroke.thin,
				Transparency = 0.35,
			}),
			Name = React.createElement("TextLabel", {
				Size = UDim2.new(0.55, -layout.gap(8), 1, 0),
				Position = UDim2.fromOffset(layout.gap(10), 0),
				BackgroundTransparency = 1,
				Text = creature.displayName,
				TextSize = layout.text(13),
				Font = theme.Font.title,
				TextColor3 = C.textMain,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			Odds = React.createElement("TextLabel", {
				Size = UDim2.new(0.45, -layout.gap(10), 1, 0),
				Position = UDim2.new(1, -layout.gap(10), 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = FormatOneIn(creature.oneIn),
				TextSize = layout.text(15),
				Font = theme.Font.heavy,
				TextColor3 = band,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		})
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.veil,
		BackgroundTransparency = 0.35,
		ZIndex = 22,
	}, {
		Hit = React.createElement("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			[React.Event.Activated] = props.onClose,
		}),
		PanelWrap = React.createElement("Frame", {
			Size = UDim2.fromOffset(layout.px(360), layout.px(420)),
			Position = UDim2.fromScale(0.5, 0.48),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = 23,
		}, {
		Panel = React.createElement(PanelChrome, {
			title = "PETS",
			subtitle = `{#ctx.hud.creatures} owned`,
			size = UDim2.fromScale(1, 1),
			zIndex = 23,
			children = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				List = React.createElement("UIListLayout", {
					Padding = UDim.new(0, layout.gap(8)),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Scroll = React.createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 0, layout.px(300)),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 4,
					ScrollBarImageColor3 = C.goldDeep,
					CanvasSize = UDim2.fromOffset(0, math.max(#ctx.hud.creatures, 1) * layout.px(54)),
					LayoutOrder = 1,
				}, {
					Layout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, layout.gap(6)),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Empty = if #ctx.hud.creatures == 0
						then React.createElement("TextLabel", {
							Size = UDim2.new(1, 0, 0, layout.px(48)),
							BackgroundTransparency = 1,
							Text = "No pets yet — open Shop to roll",
							TextSize = layout.text(13),
							Font = theme.Font.body,
							TextColor3 = C.textMuted,
						})
						else nil,
					Rows = React.createElement(React.Fragment, nil, rows),
				}),
				Actions = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, layout.px(40)),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					List = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, layout.gap(8)),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),
					Breed = React.createElement(OrnateButton, {
						text = "Breed",
						variant = "jade",
						width = 120,
						onClick = props.onBreed,
					}),
					Close = React.createElement(OrnateButton, {
						text = "Close",
						variant = "ghost",
						width = 120,
						onClick = props.onClose,
					}),
				}),
			}),
			}),
		}),
	})
end

return PetsPanel
