--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.context.HudContext)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
local Button = require(script.Parent.components.Button)
local useLayout = require(script.Parent.hooks.useLayout)
local theme = require(script.Parent.theme)
local Formatters = require(script.Parent.util.Formatters)

export type Props = {
	upgradeId: string,
	label: string,
}

local function UpgradeRow(props: Props): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	local level = ctx.hud.upgrades[props.upgradeId] or 0
	local cost = UpgradeLogic.cost(props.upgradeId, level) or 0
	local maxed = UpgradeLogic.isMaxLevel(props.upgradeId, level)
	local canBuy = not maxed and ctx.hud.coins >= cost

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, layout.px(theme.Design.ROW_H)),
		BackgroundColor3 = theme.Colors.bg3,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.fromOffset(layout.gap(12), 0),
			BackgroundTransparency = 1,
			Text = `{props.label} Lv.{level}`,
			TextSize = layout.text(14),
			Font = theme.Font.body,
			TextColor3 = theme.Colors.textMain,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Buy = React.createElement(Button, {
			label = if maxed then "MAX" else Formatters.shortNumber(cost),
			variant = if canBuy then "sell" else "secondary",
			disabled = not canBuy,
			onActivated = function()
				ctx.buyUpgrade(props.upgradeId)
			end,
		}),
	})
end

return UpgradeRow
