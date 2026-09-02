--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	vertical: boolean?,
	color: Color3?,
	thickness: number?,
	layoutOrder: number?,
	position: UDim2?,
}

local function Divider(props: Props): React.Node
	local layout = useLayout()
	local thickness = layout.px(props.thickness or 2)
	local vertical = props.vertical == true

	return React.createElement("Frame", {
		Size = if vertical then UDim2.new(0, thickness, 1, 0) else UDim2.new(1, 0, 0, thickness),
		BackgroundColor3 = props.color or theme.Border.soft,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Position = props.position,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
	})
end

return Divider
