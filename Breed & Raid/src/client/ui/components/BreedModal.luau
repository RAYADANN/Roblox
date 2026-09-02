--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BreedConfig = require(ReplicatedStorage.shared.data.BreedConfig)
local BreedLogic = require(ReplicatedStorage.shared.util.BreedLogic)
local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local Formatters = require(script.Parent.Parent.util.Formatters)
local HudContext = require(script.Parent.Parent.context.HudContext)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Badge = require(script.Parent.Badge)
local EmptyState = require(script.Parent.EmptyState)
local ItemCard = require(script.Parent.ItemCard)
local Modal = require(script.Parent.Modal)
local OneInBadge = require(script.Parent.OneInBadge)
local OrnateButton = require(script.Parent.OrnateButton)
local ProgressBar = require(script.Parent.ProgressBar)

local function findCreature(creatures: { any }, id: string): any?
	for _, creature in creatures do
		if creature.id == id then
			return creature
		end
	end
	return nil
end

local function BreedModal(): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	local now, setNow = React.useState(os.time())
	local incubate = ctx.hud.incubate

	React.useEffect(function()
		if not ctx.breedOpen or not incubate then
			return
		end
		local last = 0
		local connection = RunService.Heartbeat:Connect(function()
			local current = os.time()
			if current ~= last then
				last = current
				setNow(current)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { ctx.breedOpen, incubate ~= nil })

	local parentA = if ctx.selected[1] then findCreature(ctx.hud.creatures, ctx.selected[1]) else nil
	local parentB = if ctx.selected[2] then findCreature(ctx.hud.creatures, ctx.selected[2]) else nil
	local expected = if parentA and parentB then parentA.oneIn * parentB.oneIn else nil
	local leftSec = 0
	local progress = 0
	if incubate then
		local total = math.max(1, incubate.endsAt - incubate.startedAt)
		leftSec = math.max(0, incubate.endsAt - now)
		progress = math.clamp(1 - leftSec / total, 0, 1)
	end
	local speedCost = if incubate and not incubate.spedUp
		then BreedLogic.softSpeedCost(incubate.startedAt, os.time(), BreedConfig.firstSpeedFree)
		else nil

	local cardWidth = if layout.isPhone then 130 else 148
	local cardHeight = if layout.isPhone then 184 else 202
	local cards: { [string]: React.Node } = {
		Grid = React.createElement("UIGridLayout", {
			CellSize = UDim2.fromOffset(layout.px(cardWidth), layout.px(cardHeight)),
			CellPadding = UDim2.fromOffset(layout.gap(9), layout.gap(9)),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for index, creature in ctx.hud.creatures do
		local selected = table.find(ctx.selected, creature.id) ~= nil
		cards[`Creature{index}`] = React.createElement(ItemCard, {
			title = creature.displayName,
			subtitle = creature.nestId or "storage",
			icon = "pets",
			accent = theme.rarityColor(creature.rarity),
			badge = if selected then "SELECTED" else creature.rarity,
			selected = selected,
			disabled = incubate ~= nil,
			width = cardWidth,
			height = cardHeight,
			layoutOrder = index,
			onClick = function()
				ctx.toggleSelect(creature.id)
			end,
			footer = React.createElement(OneInBadge, {
				oneIn = creature.oneIn,
				rarity = creature.rarity,
				compact = true,
			}),
		})
	end

	local subtitle = if incubate
		then `Incubating · {leftSec}s remaining`
		else `{#ctx.selected}/2 parents selected`

	return React.createElement(Modal, {
		visible = ctx.breedOpen,
		title = "FUSE LAB",
		subtitle = subtitle,
		accent = theme.Action.breed,
		width = 650,
		height = 600,
		onClose = function()
			ctx.setBreedOpen(false)
		end,
		zIndex = 28,
	}, React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Chase = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, layout.px(if incubate then 84 else 72)),
			BackgroundColor3 = theme.Surface.tinted,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.md }),
			Stroke = React.createElement("UIStroke", {
				Color = theme.Action.reward,
				Thickness = theme.Stroke.medium,
			}),
			Badge = React.createElement(Badge, {
				text = if incubate then "ROULETTE LOADING" else "JACKPOT CHASE",
				accent = theme.Action.breed,
				width = 154,
				position = UDim2.fromOffset(layout.gap(10), layout.gap(8)),
			}),
			Copy = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(190), 0, layout.px(48)),
				Position = UDim2.new(1, -layout.gap(10), 0, layout.gap(5)),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = if incubate
					then `Expected {FormatOneIn(incubate.expectedOneIn)} · up to {FormatOneIn(BreedLogic.jackpotCeiling(incubate.expectedOneIn))}`
					elseif expected
					then `Expected {FormatOneIn(expected)} · up to {FormatOneIn(BreedLogic.jackpotCeiling(expected))}`
					else "Pick two parents. Their one-in values multiply.",
				TextSize = layout.text(13),
				Font = theme.Font.heavy,
				TextColor3 = theme.Action.rewardShadow,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
			Progress = if incubate
				then React.createElement("Frame", {
					Size = UDim2.new(1, -layout.gap(20), 0, layout.px(16)),
					Position = UDim2.new(0, layout.gap(10), 1, -layout.gap(22)),
					BackgroundTransparency = 1,
				}, {
					Bar = React.createElement(ProgressBar, {
						progress = progress,
						height = 16,
						accent = if leftSec <= 10 then theme.Semantic.warning else theme.Action.breed,
						label = `${leftSec}s`,
					}),
				})
				else nil,
		}),
		List = if #ctx.hud.creatures == 0
			then React.createElement(EmptyState, {
				title = "No parents available",
				description = "Roll creatures before opening the Fuse Lab.",
				icon = "breed",
				accent = theme.Action.breed,
			})
			else React.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -layout.px(172)),
				Position = UDim2.fromOffset(0, layout.px(96)),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 5,
				ScrollBarImageColor3 = theme.Action.breed,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromOffset(0, 0),
			}, cards),
		Actions = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, layout.px(60)),
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
		}, {
			List = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, layout.gap(10)),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Start = if not incubate
				then React.createElement(OrnateButton, {
					text = if expected then `FUSE · {FormatOneIn(expected)}` else "SELECT 2 PARENTS",
					variant = "primary",
					icon = "breed",
					width = 270,
					onClick = ctx.startBreed,
					disabled = expected == nil,
				})
				else nil,
			Speed = if incubate and speedCost ~= nil
				then React.createElement(OrnateButton, {
					text = if speedCost == 0 then "FREE SPEED ×2" else `SPEED · ${Formatters.shortNumber(speedCost)}`,
					variant = "gold",
					icon = "forward",
					width = 210,
					onClick = ctx.softSpeedBreed,
				})
				else nil,
			Cancel = if incubate
				then React.createElement(OrnateButton, {
					text = "Cancel",
					variant = "danger",
					width = 120,
					onClick = ctx.cancelBreed,
				})
				else nil,
		}),
	}))
end

return BreedModal
