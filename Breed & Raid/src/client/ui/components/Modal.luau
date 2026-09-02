--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local WindowShell = require(script.Parent.WindowShell)

export type Props = {
	visible: boolean,
	title: string,
	subtitle: string?,
	accent: Color3?,
	width: number?,
	height: number?,
	onClose: (() -> ())?,
	zIndex: number?,
	children: React.Node?,
}

local function Modal(props: Props): React.Node
	local layout = useLayout()
	if not props.visible then
		return nil
	end

	local width = props.width or theme.Design.MODAL_W
	local height = props.height or theme.Design.MODAL_H
	local fit = layout.modalFitScale(width, height)
	local zIndex = props.zIndex or 100
	local centerX = layout.safeLeft + (layout.viewport.X - layout.safeLeft - layout.safeRight) / 2
	local centerY = layout.safeTop + (layout.viewport.Y - layout.safeTop - layout.safeBottom) / 2

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Surface.overlay,
		BackgroundTransparency = theme.Opacity.overlay,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = zIndex,
	}, {
		Host = React.createElement("Frame", {
			Size = UDim2.fromOffset(layout.px(width), layout.px(height)),
			Position = UDim2.fromOffset(centerX, centerY),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = zIndex + 1,
		}, {
			Scale = React.createElement("UIScale", { Scale = fit }),
			Window = React.createElement(WindowShell, {
				title = props.title,
				subtitle = props.subtitle,
				accent = props.accent,
				size = UDim2.fromScale(1, 1),
				onClose = props.onClose,
				zIndex = zIndex + 1,
				children = props.children,
			}),
		}),
	})
end

return Modal
