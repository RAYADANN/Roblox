--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local Shadow = require(script.Parent.Shadow)

export type Tone = "base" | "raised" | "sunken" | "tinted"
export type Props = {
	tone: Tone?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
	radius: UDim?,
	strokeColor: Color3?,
	strokeThickness: number?,
	shadow: boolean?,
	shadowColor: Color3?,
	clipsDescendants: boolean?,
	children: React.Node?,
}

local function toneColor(tone: Tone): Color3
	if tone == "raised" then
		return theme.Surface.raised
	elseif tone == "sunken" then
		return theme.Surface.sunken
	elseif tone == "tinted" then
		return theme.Surface.tinted
	end
	return theme.Surface.base
end

local function Surface(props: Props): React.Node
	local radius = props.radius or theme.Radius.panel

	return React.createElement("Frame", {
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
	}, {
		Shadow = if props.shadow == false
			then nil
			else React.createElement(Shadow, {
				color = props.shadowColor,
				radius = radius,
				zIndex = props.zIndex,
			}),
		Face = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = toneColor(props.tone or "base"),
			BorderSizePixel = 0,
			ClipsDescendants = props.clipsDescendants == true,
			ZIndex = (props.zIndex or 1) + 1,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = radius }),
			Stroke = React.createElement("UIStroke", {
				Color = props.strokeColor or theme.Border.light,
				Thickness = props.strokeThickness or theme.Stroke.medium,
			}),
			Content = props.children,
		}),
	})
end

return Surface
