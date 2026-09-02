--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	color: Color3?,
	depth: number?,
	radius: UDim?,
	transparency: number?,
	zIndex: number?,
}

local function Shadow(props: Props): React.Node
	local layout = useLayout()
	local depth = layout.px(props.depth or theme.Elevation.medium)

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromOffset(0, depth),
		BackgroundColor3 = props.color or theme.Action.neutralShadow,
		BackgroundTransparency = props.transparency or theme.Opacity.shadow,
		BorderSizePixel = 0,
		ZIndex = props.zIndex or 1,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = props.radius or theme.Radius.panel,
		}),
	})
end

return Shadow
