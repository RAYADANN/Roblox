--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local IconRegistry = require(script.Parent.Parent.icons.IconRegistry)

export type Props = {
	name: string,
	size: number?,
	color: Color3?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
}

local function Icon(props: Props): React.Node
	local layout = useLayout()
	local definition = IconRegistry.get(props.name)
	local size = layout.px(props.size or theme.Design.ICON_MD)
	local common = {
		Size = UDim2.fromOffset(size, size),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
	}

	if definition.image then
		return React.createElement("ImageLabel", {
			Size = common.Size,
			Position = common.Position,
			AnchorPoint = common.AnchorPoint,
			BackgroundTransparency = 1,
			LayoutOrder = common.LayoutOrder,
			ZIndex = common.ZIndex,
			Image = definition.image,
			ImageColor3 = props.color or theme.Icon.tint,
			ScaleType = Enum.ScaleType.Fit,
		})
	end

	return React.createElement("TextLabel", {
		Size = common.Size,
		Position = common.Position,
		AnchorPoint = common.AnchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = common.LayoutOrder,
		ZIndex = common.ZIndex,
		Text = definition.glyph,
		TextSize = layout.text((props.size or theme.Design.ICON_MD) * 0.82),
		Font = theme.Font.heavy,
		TextColor3 = props.color or theme.Icon.tint,
	})
end

return Icon
