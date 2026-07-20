--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.context.HudContext)
local ResourceChip = require(script.Parent.components.ResourceChip)
local UpgradeRow = require(script.Parent.components.UpgradeRow)
local ProgressBar = require(script.Parent.components.ProgressBar)
local useLayout = require(script.Parent.hooks.useLayout)
local theme = require(script.Parent.theme)

local function App(): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Top = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, layout.px(52)),
			Position = UDim2.fromOffset(layout.safeLeft, layout.safeTop),
			BackgroundTransparency = 1,
		}, {
			Chip = React.createElement(ResourceChip, { amount = ctx.hud.coins }),
		}),
		Upgrades = React.createElement("Frame", {
			Size = UDim2.new(0.4, 0, 0.4, 0),
			Position = UDim2.new(1, -layout.gap(16), 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = theme.Colors.panelBg,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, layout.gap(12)),
				PaddingBottom = UDim.new(0, layout.gap(12)),
				PaddingLeft = UDim.new(0, layout.gap(12)),
				PaddingRight = UDim.new(0, layout.gap(12)),
			}),
			List = React.createElement("UIListLayout", {
				Padding = UDim.new(0, layout.gap(8)),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Pickaxe = React.createElement(UpgradeRow, { upgradeId = "pickaxe", label = "Pickaxe" }),
			Backpack = React.createElement(UpgradeRow, { upgradeId = "backpack", label = "Backpack" }),
			Depth = React.createElement(ProgressBar, {
				progress = math.clamp(ctx.hud.rebirths / 10, 0, 1),
				height = 12,
				accent = theme.Colors.primary,
			}),
		}),
	})
end

return App
