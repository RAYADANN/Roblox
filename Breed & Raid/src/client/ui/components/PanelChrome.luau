--!strict
-- Arcade dark panel chrome — navy surface, gold title, accent bar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	title: string?,
	subtitle: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	zIndex: number?,
	layoutOrder: number?,
	children: React.Node?,
}

local function PanelChrome(props: Props): React.Node
	local layout = useLayout()
	local C = theme.Colors
	local headerH = layout.px(theme.Design.HEADER_H)

	return React.createElement("Frame", {
		Size = props.size or UDim2.fromOffset(layout.px(theme.Design.MODAL_W), layout.px(theme.Design.MODAL_H)),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundColor3 = C.panelBg,
		BorderSizePixel = 0,
		ZIndex = props.zIndex,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
		OuterStroke = React.createElement("UIStroke", {
			Color = C.outline,
			Thickness = theme.Stroke.thin,
			Transparency = 0.75,
		}),
		Header = if props.title
			then React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, headerH),
				BackgroundColor3 = C.panelHeader,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
				Squash = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, layout.px(16)),
					Position = UDim2.new(0, 0, 1, -layout.px(16)),
					BackgroundColor3 = C.panelHeader,
					BorderSizePixel = 0,
				}),
				Accent = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, layout.px(3)),
					Position = UDim2.new(0, 0, 1, 0),
					AnchorPoint = Vector2.new(0, 1),
					BackgroundColor3 = C.jade,
					BorderSizePixel = 0,
				}),
				Title = React.createElement("TextLabel", {
					Size = UDim2.new(1, -layout.px(28), 0, layout.px(22)),
					Position = UDim2.fromOffset(layout.px(14), layout.px(8)),
					BackgroundTransparency = 1,
					Text = props.title,
					TextSize = layout.text(17),
					Font = theme.Font.title,
					TextColor3 = C.goldHi,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Sub = if props.subtitle
					then React.createElement("TextLabel", {
						Size = UDim2.new(0.55, 0, 0, layout.px(14)),
						Position = UDim2.new(1, -layout.px(14), 0, layout.px(12)),
						AnchorPoint = Vector2.new(1, 0),
						BackgroundTransparency = 1,
						Text = props.subtitle,
						TextSize = layout.text(11),
						Font = theme.Font.body,
						TextColor3 = C.textMuted,
						TextXAlignment = Enum.TextXAlignment.Right,
					})
					else nil,
			})
			else nil,
		Body = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, if props.title then -headerH else 0),
			Position = UDim2.fromOffset(0, if props.title then headerH else 0),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			Pad = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, layout.gap(theme.Design.PAD_MD)),
				PaddingBottom = UDim.new(0, layout.gap(theme.Design.PAD_MD)),
				PaddingLeft = UDim.new(0, layout.gap(theme.Design.PAD_MD)),
				PaddingRight = UDim.new(0, layout.gap(theme.Design.PAD_MD)),
			}),
			Content = props.children,
		}),
	})
end

return PanelChrome
