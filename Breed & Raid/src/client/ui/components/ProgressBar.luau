--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	progress: number,
	height: number?,
	accent: Color3?,
	backgroundColor: Color3?,
	label: string?,
	layoutOrder: number?,
}

local function ProgressBar(props: Props): React.Node
	local layout = useLayout()
	local height = layout.px(props.height or 18)
	local progress = math.clamp(props.progress, 0, 1)

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = props.backgroundColor or theme.Surface.sunken,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		ClipsDescendants = true,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Border.light,
			Thickness = theme.Stroke.thin,
		}),
		Fill = React.createElement("Frame", {
			Size = UDim2.new(progress, 0, 1, 0),
			BackgroundColor3 = props.accent or theme.Action.collect,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
			Shine = React.createElement("Frame", {
				Size = UDim2.new(1, -layout.px(8), 0, layout.px(4)),
				Position = UDim2.fromOffset(layout.px(4), layout.px(3)),
				BackgroundColor3 = theme.Border.light,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
			}),
		}),
		Label = if props.label
			then React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = props.label,
				TextSize = layout.text(11),
				Font = theme.Font.heavy,
				TextColor3 = theme.Content.primary,
				ZIndex = 3,
			})
			else nil,
	})
end

return ProgressBar
