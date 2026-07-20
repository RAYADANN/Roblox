--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Button = require(script.Parent.Button)
local PetDatabase = require(ReplicatedStorage:WaitForChild("shared").data.PetDatabase)

export type Props = {
	inventory: { string },
	selectedInvIndex: number?,
	onSelect: (index: number) -> (),
	onRelease: () -> (),
}

local function InventoryPanel(props: Props): React.Node?
	local layout = useLayout()
	if #props.inventory == 0 then
		return nil
	end

	local children: { [string]: React.Node } = {
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, layout.px(24)),
			BackgroundTransparency = 1,
			Text = "Bag (stolen / leftover) → send to base",
			TextSize = layout.text(12),
			Font = theme.Font.body,
			TextColor3 = theme.Colors.textSub,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,
		}),
		List = React.createElement("UIListLayout", {
			Padding = UDim.new(0, layout.gap(4)),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, petId in props.inventory do
		local def = PetDatabase[petId]
		local selected = props.selectedInvIndex == i
		children["Pet" .. i] = React.createElement("TextButton", {
			Size = UDim2.new(1, 0, 0, layout.px(28)),
			BackgroundColor3 = if selected then theme.Colors.primary else theme.Colors.bg3,
			BorderSizePixel = 0,
			Text = if def then `{def.displayName}  +{def.incomePerSec}/s` else petId,
			TextSize = layout.text(13),
			Font = theme.Font.body,
			TextColor3 = theme.Colors.textMain,
			LayoutOrder = i,
			[React.Event.Activated] = function()
				props.onSelect(i)
			end,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		})
	end

	if props.selectedInvIndex then
		children.Release = React.createElement(Button, {
			label = "Send to base",
			variant = "primary",
			layoutOrder = 100,
			onActivated = props.onRelease,
		})
	end

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.px(280), layout.px(200)),
		Position = UDim2.new(0, layout.safeLeft + layout.gap(16), 1, -layout.gap(24)),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = theme.Colors.panelBg,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.dockBorder,
			Thickness = theme.Stroke.thin,
		}),
		Pad = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, layout.gap(8)),
			PaddingBottom = UDim.new(0, layout.gap(8)),
			PaddingLeft = UDim.new(0, layout.gap(10)),
			PaddingRight = UDim.new(0, layout.gap(10)),
		}),
		Content = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, children),
	})
end

return InventoryPanel
