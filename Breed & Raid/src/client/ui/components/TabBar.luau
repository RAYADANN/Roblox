--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local Icon = require(script.Parent.Icon)

export type Tab = {
	id: string,
	label: string,
	icon: string?,
}

export type Props = {
	tabs: { Tab },
	selectedId: string,
	onSelect: (id: string) -> (),
	height: number?,
	accent: Color3?,
	layoutOrder: number?,
}

local function TabBar(props: Props): React.Node
	local layout = useLayout()
	local accent = props.accent or theme.Action.primary
	local height = layout.touch(props.height or 50)
	local children: { [string]: React.Node } = {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, layout.gap(6)),
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, layout.gap(6)),
			PaddingRight = UDim.new(0, layout.gap(6)),
		}),
	}

	for index, tab in props.tabs do
		local selected = tab.id == props.selectedId
		children[tab.id] = React.createElement("TextButton", {
			Size = UDim2.new(1 / math.max(1, #props.tabs), -layout.gap(6), 1, -layout.gap(8)),
			BackgroundColor3 = if selected then accent else theme.Surface.raised,
			BorderSizePixel = 0,
			Text = if tab.icon then "" else tab.label,
			TextSize = layout.text(13),
			Font = theme.Font.heavy,
			TextColor3 = if selected then theme.Content.inverse else theme.Content.secondary,
			AutoButtonColor = false,
			LayoutOrder = index,
			[React.Event.Activated] = function()
				props.onSelect(tab.id)
			end,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.badge }),
			Stroke = React.createElement("UIStroke", {
				Color = if selected then theme.Border.light else theme.Border.soft,
				Thickness = theme.Stroke.thin,
			}),
			Icon = if tab.icon
				then React.createElement(Icon, {
					name = tab.icon,
					size = 20,
					color = if selected then theme.Content.inverse else accent,
					position = UDim2.new(0, layout.gap(10), 0.5, 0),
					anchorPoint = Vector2.new(0, 0.5),
				})
				else nil,
			Label = if tab.icon
				then React.createElement("TextLabel", {
					Size = UDim2.new(1, -layout.px(38), 1, 0),
					Position = UDim2.fromOffset(layout.gap(34), 0),
					BackgroundTransparency = 1,
					Text = tab.label,
					TextSize = layout.text(13),
					Font = theme.Font.heavy,
					TextColor3 = if selected then theme.Content.inverse else theme.Content.secondary,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				else nil,
		})
	end

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = theme.Surface.sunken,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		Tabs = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, children),
	})
end

return TabBar
