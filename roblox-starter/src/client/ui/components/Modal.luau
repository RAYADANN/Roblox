--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.theme)
local useLayout = require(script.Parent.hooks.useLayout)
local ModalChrome = require(script.Parent.components.ModalChrome)

export type Props = {
	visible: boolean,
	title: string,
	onClose: () -> (),
	children: React.Node?,
}

local function Modal(props: Props): React.Node
	local layout = useLayout()
	if not props.visible then
		return nil
	end

	local fit = layout.modalFitScale(theme.Design.MODAL_W, theme.Design.MODAL_H)

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Colors.bg1,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 10,
	}, {
		Scaled = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Scale = React.createElement("UIScale", { Scale = fit }),
			Chrome = React.createElement(ModalChrome, {
				title = props.title,
				onClose = props.onClose,
				children = props.children,
			}),
		}),
	})
end

return Modal
