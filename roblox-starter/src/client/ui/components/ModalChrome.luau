--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.theme)
local useLayout = require(script.Parent.hooks.useLayout)
local Button = require(script.Parent.components.Button)

export type Props = {
	title: string,
	accent: Color3?,
	onClose: () -> (),
	children: React.Node?,
}

local function ModalChrome(props: Props): React.Node
	local layout = useLayout()
	local accent = props.accent or theme.Colors.primary

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Shell = React.createElement("Frame", {
			Size = UDim2.fromOffset(layout.px(theme.Design.MODAL_W), layout.px(theme.Design.MODAL_H)),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme.Colors.panelBg,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
			Stroke = React.createElement("UIStroke", {
				Color = accent,
				Thickness = theme.Stroke.thick,
				Transparency = 0.12,
			}),
			AccentBar = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, layout.px(3)),
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
			}),
			Title = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(80), 0, layout.px(theme.Design.HEADER_H)),
				Position = UDim2.fromOffset(layout.gap(16), layout.gap(8)),
				BackgroundTransparency = 1,
				Text = props.title,
				TextSize = layout.text(20),
				Font = theme.Font.title,
				TextColor3 = theme.Colors.textMain,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Close = React.createElement(Button, {
				label = "X",
				variant = "secondary",
				onActivated = props.onClose,
			}),
			Content = React.createElement("Frame", {
				Size = UDim2.new(1, -layout.gap(24), 1, -layout.px(theme.Design.HEADER_H + 16)),
				Position = UDim2.new(0, layout.gap(12), 0, layout.px(theme.Design.HEADER_H)),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, props.children),
		}),
	})
end

return ModalChrome
