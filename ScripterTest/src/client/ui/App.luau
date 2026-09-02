--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.context.HudContext)
local PointsChip = require(script.Parent.components.PointsChip)
local AchievementsButton = require(script.Parent.components.AchievementsButton)
local AchievementsPanel = require(script.Parent.panels.AchievementsPanel)

local function App(): React.Node
	local ctx = React.useContext(HudContext)

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Currencies = React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 0, 24),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
		}, {
			Chip = React.createElement(PointsChip, { amount = ctx.hud.points }),
		}),
		Left = React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0, 28, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			Btn = React.createElement(AchievementsButton, {
				onActivated = function()
					ctx.setAchievementsOpen(true)
				end,
			}),
		}),
		Panel = React.createElement(AchievementsPanel, {
			visible = ctx.achievementsOpen,
			hud = ctx.hud,
			onClose = function()
				ctx.setAchievementsOpen(false)
			end,
		}),
	})
end

return App
