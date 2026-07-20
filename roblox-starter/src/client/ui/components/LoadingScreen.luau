--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.theme)
local useLayout = require(script.Parent.hooks.useLayout)
local ProgressBar = require(script.Parent.components.ProgressBar)

export type Props = {
	progress: number,
	visible: boolean,
}

local function LoadingScreen(props: Props): React.Node
	local layout = useLayout()
	if not props.visible then
		return nil
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Colors.bg1,
		BorderSizePixel = 0,
		ZIndex = 1000,
	}, {
		Title = React.createElement("TextLabel", {
			Size = UDim2.fromOffset(layout.px(300), layout.px(48)),
			Position = UDim2.fromScale(0.5, 0.45),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "Loading...",
			TextSize = layout.text(24),
			Font = theme.Font.heavy,
			TextColor3 = theme.Colors.textMain,
		}),
		Bar = React.createElement(ProgressBar, {
			progress = props.progress,
			height = 8,
		}),
	})
end

return LoadingScreen
