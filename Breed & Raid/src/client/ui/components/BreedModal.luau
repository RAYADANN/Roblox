--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local BreedLogic = require(ReplicatedStorage.shared.util.BreedLogic)
local Formatters = require(script.Parent.Parent.util.Formatters)
local HudContext = require(script.Parent.Parent.context.HudContext)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local PanelChrome = require(script.Parent.PanelChrome)
local OrnateButton = require(script.Parent.OrnateButton)

local function BreedModal(): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	if not ctx.breedOpen then
		return React.createElement(React.Fragment)
	end

	local C = theme.Colors
	local incubate = ctx.hud.incubate
	local canStart = not incubate and #ctx.selected >= 2
	-- Match server BreedService (os.time), not Workspace:GetServerTimeNow().
	local speedCost = if incubate and not incubate.spedUp
		then BreedLogic.softSpeedCost(incubate.startedAt, os.time())
		else nil

	local rows = {}
	for i, creature in ctx.hud.creatures do
		local selected = table.find(ctx.selected, creature.id) ~= nil
		local band = theme.rarityColor(creature.rarity)
		rows["c" .. i] = React.createElement("TextButton", {
			Size = UDim2.new(1, 0, 0, layout.px(44)),
			BackgroundColor3 = if selected then C.bg2 else C.bg4,
			Text = "",
			AutoButtonColor = false,
			Active = incubate == nil,
			LayoutOrder = i,
			[React.Event.Activated] = function()
				if incubate then
					return
				end
				ctx.toggleSelect(creature.id)
			end,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
			Stroke = React.createElement("UIStroke", {
				Color = if selected then C.jade else band,
				Thickness = if selected then 2.5 else 1.5,
			}),
			Name = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(16), 0, layout.px(16)),
				Position = UDim2.fromOffset(layout.px(10), layout.px(4)),
				BackgroundTransparency = 1,
				Text = creature.displayName,
				TextSize = layout.text(12),
				Font = theme.Font.title,
				TextColor3 = C.textMain,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Odds = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(16), 0, layout.px(18)),
				Position = UDim2.fromOffset(layout.px(10), layout.px(20)),
				BackgroundTransparency = 1,
				Text = `{FormatOneIn(creature.oneIn)} · {creature.nestId or "bag"}`,
				TextSize = layout.text(13),
				Font = theme.Font.heavy,
				TextColor3 = band,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		})
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.veil,
		BackgroundTransparency = 0.4,
		ZIndex = 20,
	}, {
		Panel = React.createElement(PanelChrome, {
			title = "FUSE",
			subtitle = if incubate then "Incubating" else "Pick 2 parents",
			size = UDim2.fromOffset(layout.px(380), layout.px(440)),
			position = UDim2.fromScale(0.5, 0.5),
			anchorPoint = Vector2.new(0.5, 0.5),
			zIndex = 21,
			children = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				List = React.createElement("UIListLayout", {
					Padding = UDim.new(0, layout.gap(8)),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Hint = React.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, layout.px(36)),
					BackgroundTransparency = 1,
					Text = if incubate
						then `Incubating… expected ~ {FormatOneIn(incubate.expectedOneIn)}`
						else "Parents consumed on success. Jackpot may multiply oneIn.",
					TextSize = layout.text(12),
					Font = theme.Font.body,
					TextColor3 = C.textMuted,
					TextWrapped = true,
					LayoutOrder = 1,
				}),
				Scroll = React.createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 0, layout.px(250)),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 4,
					ScrollBarImageColor3 = C.goldDeep,
					CanvasSize = UDim2.fromOffset(0, #ctx.hud.creatures * layout.px(50)),
					LayoutOrder = 2,
				}, {
					List = React.createElement("UIListLayout", {
						Padding = UDim.new(0, layout.gap(6)),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Rows = React.createElement(React.Fragment, nil, rows),
				}),
				Actions = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, layout.px(40)),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}, {
					List = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, layout.gap(8)),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),
					Start = if not incubate
						then React.createElement(OrnateButton, {
							text = "Start",
							variant = "jade",
							onClick = ctx.startBreed,
							width = 100,
							disabled = not canStart,
						})
						else nil,
					Speed = if incubate and speedCost ~= nil
						then React.createElement(OrnateButton, {
							text = `Speed · ${Formatters.shortNumber(speedCost)}`,
							variant = "gold",
							onClick = ctx.softSpeedBreed,
							width = 140,
						})
						else nil,
					CancelJob = if incubate
						then React.createElement(OrnateButton, {
							text = "Cancel",
							variant = "danger",
							onClick = ctx.cancelBreed,
							width = 100,
						})
						else nil,
					Close = React.createElement(OrnateButton, {
						text = "Close",
						variant = "ghost",
						onClick = function()
							ctx.setBreedOpen(false)
						end,
						width = 100,
					}),
				}),
			}),
		}),
	})
end

return BreedModal
