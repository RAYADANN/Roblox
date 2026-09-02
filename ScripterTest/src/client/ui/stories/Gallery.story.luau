--!strict
-- Hoarcekat: галерея UI-атомов тестового задания.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local PointsChip = require(script.Parent.Parent.components.PointsChip)
local AchievementsButton = require(script.Parent.Parent.components.AchievementsButton)
local AchievementsPanel = require(script.Parent.Parent.panels.AchievementsPanel)
local ProximityPromptUI = require(script.Parent.Parent.components.ProximityPromptUI)
local ToastStack = require(script.Parent.Parent.components.ToastStack)
local OutlinedText = require(script.Parent.Parent.components.OutlinedText)
local CloseButton = require(script.Parent.Parent.components.CloseButton)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local theme = require(script.Parent.Parent.theme)
local mount = require(script.Parent.mount)

local function section(title: string, order: number, child: React.Node): React.Node
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, {
		Title = React.createElement(OutlinedText, {
			text = title,
			size = UDim2.new(1, 0, 0, 36),
			variant = "title",
			layoutOrder = 1,
		}),
		Body = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.fromOffset(0, 44),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Child = child,
		}),
	})
end

local function Gallery(): React.Node
	local hud = NetTypes.emptyHud()
	hud.points = 125
	hud.jumpCount = 3
	hud.achFallOffMap = true

	return React.createElement("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Colors.bg,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		Pad = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 24),
			PaddingBottom = UDim.new(0, 48),
			PaddingLeft = UDim.new(0, 32),
			PaddingRight = UDim.new(0, 32),
		}),
		List = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 28),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Points = section(
			"POINTS CHIP",
			1,
			React.createElement(PointsChip, { amount = 12500 })
		),
		AchBtn = section(
			"ACHIEVEMENTS BUTTON",
			2,
			React.createElement(AchievementsButton, { onActivated = function() end })
		),
		Close = section(
			"CLOSE BUTTON",
			3,
			React.createElement(CloseButton, {
				size = UDim2.fromOffset(56, 56),
				onActivated = function() end,
			})
		),
		Prompt = section(
			"PROXIMITY PROMPT",
			4,
			React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 100),
				BackgroundTransparency = 1,
			}, {
				UI = React.createElement(ProximityPromptUI, {
					prompt = {
						keyText = "E",
						objectText = "Object Text",
						actionText = "Action Text",
						inputType = Enum.ProximityPromptInputType.Keyboard,
					},
				}),
			})
		),
		Toasts = section(
			"TOASTS",
			5,
			React.createElement(ToastStack, {
				items = {
					{ id = 1, text = "Shop purchase OK", color = theme.Colors.buy },
					{ id = 2, text = "Not enough points", color = theme.Colors.closeX },
				},
			})
		),
		Panel = section(
			"ACHIEVEMENTS WINDOW",
			6,
			React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 520),
				BackgroundTransparency = 1,
			}, {
				Panel = React.createElement(AchievementsPanel, {
					visible = true,
					hud = hud,
					onClose = function() end,
				}),
			})
		),
	})
end

return mount(React.createElement(Gallery))
