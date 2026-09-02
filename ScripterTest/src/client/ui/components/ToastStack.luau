--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type ToastItem = {
	id: number,
	text: string,
	color: Color3,
}

export type Props = {
	items: { ToastItem },
}

local function ToastStack(props: Props): React.Node
	local children: { [string]: React.Node } = {
		List = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, item in props.items do
		children[`T{item.id}`] = React.createElement("TextLabel", {
			Size = UDim2.fromOffset(420, 44),
			BackgroundTransparency = 1,
			Text = item.text,
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = item.color,
			LayoutOrder = i,
		}, {
			Pad = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
			Outline = React.createElement("UIStroke", {
				Color = theme.Colors.black,
				Thickness = theme.Stroke.title,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		})
	end

	return React.createElement("Frame", {
		Name = "ToastStack",
		Size = UDim2.new(1, 0, 0, 200),
		Position = UDim2.new(0.5, 0, 0, 90),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
	}, children)
end

return ToastStack
