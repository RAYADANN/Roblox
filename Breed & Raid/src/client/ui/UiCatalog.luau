--!strict
-- Studio-only component catalog. Intentionally not mounted by GameRoot.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.theme)
local Badge = require(script.Parent.components.Badge)
local EmptyState = require(script.Parent.components.EmptyState)
local ItemCard = require(script.Parent.components.ItemCard)
local OneInBadge = require(script.Parent.components.OneInBadge)
local OrnateButton = require(script.Parent.components.OrnateButton)
local ProgressBar = require(script.Parent.components.ProgressBar)
local StatusChip = require(script.Parent.components.StatusChip)
local Toast = require(script.Parent.components.Toast)
local WindowShell = require(script.Parent.components.WindowShell)

local noop = function() end

local function UiCatalog(): React.Node
	if not RunService:IsStudio() then
		return nil
	end

	return React.createElement(WindowShell, {
		title = "TOYBOX UI CATALOG",
		subtitle = "Studio harness · not mounted in production",
		accent = theme.Action.primary,
		size = UDim2.fromOffset(900, 620),
		position = UDim2.fromScale(0.5, 0.5),
		anchorPoint = Vector2.new(0.5, 0.5),
	}, React.createElement("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	}, {
		Layout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		StatusRow = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
			}),
			Ready = React.createElement(StatusChip, { text = "Ready", tone = "success" }),
			Warning = React.createElement(StatusChip, { text = "Locked 32s", tone = "warning" }),
			Badge = React.createElement(Badge, { text = "Hybrid", accent = theme.Action.breed }),
		}),
		Odds = React.createElement(OneInBadge, {
			oneIn = 12500,
			rarity = "Secret",
			layoutOrder = 2,
		}),
		Progress = React.createElement(ProgressBar, {
			progress = 0.64,
			label = "FUSING · 43s",
			accent = theme.Action.breed,
			layoutOrder = 3,
		}),
		Buttons = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 64),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 12),
			}),
			Primary = React.createElement(OrnateButton, {
				text = "Primary",
				variant = "primary",
				icon = "check",
				onClick = noop,
			}),
			Reward = React.createElement(OrnateButton, {
				text = "Reward",
				variant = "gold",
				onClick = noop,
			}),
			Danger = React.createElement(OrnateButton, {
				text = "Danger",
				variant = "danger",
				onClick = noop,
			}),
			Disabled = React.createElement(OrnateButton, {
				text = "Disabled",
				variant = "ghost",
				disabled = true,
				onClick = noop,
			}),
		}),
		CardRow = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 220),
			BackgroundTransparency = 1,
			LayoutOrder = 5,
		}, {
			Card = React.createElement(ItemCard, {
				title = "Glitch Owl",
				subtitle = "400/s · N4",
				icon = "pets",
				accent = theme.Rarity.secret,
				badge = "HYBRID",
				selected = true,
				footer = React.createElement(OneInBadge, {
					oneIn = 10000,
					rarity = "Secret",
					compact = true,
				}),
			}),
			Empty = React.createElement("Frame", {
				Size = UDim2.new(1, -200, 1, 0),
				Position = UDim2.fromOffset(200, 0),
				BackgroundTransparency = 1,
			}, {
				State = React.createElement(EmptyState, {
					title = "No creatures",
					description = "Empty-state copy and icon treatment.",
				}),
			}),
		}),
		Toast = React.createElement(Toast, {
			title = "Raid alert",
			text = "Robbed! 1 in 2.5K",
			tone = "danger",
			icon = "warning",
			layoutOrder = 6,
		}),
	}))
end

return UiCatalog
