--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Button = require(script.Parent.Button)
local BlockDatabase = require(ReplicatedStorage:WaitForChild("shared").data.BlockDatabase)

export type Props = {
	open: boolean,
	selectedBlockId: string?,
	blockInv: { [string]: number }?,
	onSelectBlock: (blockId: string) -> (),
	onClose: () -> (),
}

local ORDER = { "dirt", "wood_planks", "stone", "spikes", "lamp_t1" }

local function BuildPanel(props: Props): React.Node?
	local layout = useLayout()
	if not props.open then
		return nil
	end

	local rows: { [string]: React.Node } = {
		Layout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, layout.gap(6)),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, layout.px(40)),
			BackgroundTransparency = 1,
			Text = "Build tool: pick stack → ghost on yard grid. Take tool removes.",
			TextSize = layout.text(14),
			Font = theme.Font.title,
			TextColor3 = theme.Colors.textMain,
			TextWrapped = true,
			LayoutOrder = 0,
		}),
	}

	local order = 1
	local inv = props.blockInv or {}
	for _, id in ORDER do
		local def = BlockDatabase[id]
		if def then
			local qty = inv[id] or 0
			local selected = props.selectedBlockId == id
			rows[id] = React.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, layout.px(36)),
				BackgroundColor3 = if selected then theme.Colors.primary else theme.Colors.bg3,
				BorderSizePixel = 0,
				Text = string.format("%s  x%d  (1 in %d)", def.displayName, qty, def.oneIn),
				TextSize = layout.text(13),
				Font = theme.Font.body,
				TextColor3 = theme.Colors.textMain,
				LayoutOrder = order,
				[React.Event.Activated] = function()
					props.onSelectBlock(id)
				end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
			})
			order += 1
		end
	end

	rows.Close = React.createElement(Button, {
		label = "Close",
		variant = "secondary",
		layoutOrder = 100,
		onActivated = props.onClose,
	})

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.px(380), layout.px(320)),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Colors.panelBg,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.dockBorder,
			Thickness = theme.Stroke.medium,
		}),
		Pad = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, layout.gap(12)),
			PaddingBottom = UDim.new(0, layout.gap(12)),
			PaddingLeft = UDim.new(0, layout.gap(12)),
			PaddingRight = UDim.new(0, layout.gap(12)),
		}),
		Body = React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.fromOffset(0, layout.px(300)),
		}, rows),
	})
end

return BuildPanel
