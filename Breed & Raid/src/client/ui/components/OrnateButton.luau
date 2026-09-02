--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local UiSound = require(script.Parent.Parent.juice.UiSound)
local Icon = require(script.Parent.Icon)
local Shadow = require(script.Parent.Shadow)

export type Variant = "gold" | "jade" | "sky" | "danger" | "ghost" | "primary"

export type Props = {
	text: string,
	variant: Variant?,
	onClick: () -> (),
	layoutOrder: number?,
	width: number?,
	height: number?,
	disabled: boolean?,
	position: UDim2?,
	anchorPoint: Vector2?,
	icon: string?,
}

local function colors(variant: Variant): (Color3, Color3, Color3)
	if variant == "gold" then
		return theme.Action.reward, theme.Content.primary, theme.Action.rewardShadow
	elseif variant == "jade" then
		return theme.Action.collect, theme.Content.inverse, theme.Action.collectShadow
	elseif variant == "sky" or variant == "primary" then
		return theme.Action.primary, theme.Content.inverse, theme.Action.primaryShadow
	elseif variant == "danger" then
		return theme.Action.danger, theme.Content.inverse, theme.Action.dangerShadow
	end
	return theme.Surface.tinted, theme.Content.primary, theme.Action.neutralShadow
end

local function OrnateButton(props: Props): React.Node
	local layout = useLayout()
	local variant: Variant = props.variant or "gold"
	local bg, fg, stroke = colors(variant)
	local disabled = props.disabled == true
	local scale, handlers = useHoverPress({ disabled = disabled })
	local h = layout.px(props.height or theme.Design.BTN_H)
	local w = layout.px(props.width or 120)

	-- Dock CTAs keep touch floor; dense panel buttons pass smaller height and skip floor
	if (props.height or theme.Design.BTN_H) >= theme.Design.BTN_H then
		h = layout.touch(props.height or theme.Design.BTN_H)
	end

	return React.createElement("TextButton", {
		Size = UDim2.fromOffset(w, h),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Active = not disabled,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = function()
			if disabled then
				return
			end
			UiSound.play("click")
			props.onClick()
		end,
		[React.Event.MouseEnter] = handlers.onMouseEnter,
		[React.Event.MouseLeave] = handlers.onMouseLeave,
		[React.Event.MouseButton1Down] = handlers.onMouseDown,
		[React.Event.MouseButton1Up] = handlers.onMouseUp,
	}, {
		Scale = React.createElement("UIScale", { Scale = scale }),
		Shadow = React.createElement(Shadow, {
			color = stroke,
			depth = theme.Elevation.low,
			radius = theme.Radius.btn,
		}),
		Face = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = bg,
			BackgroundTransparency = if disabled then 0.4 else 0,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
			Stroke = React.createElement("UIStroke", {
				Color = theme.Border.light,
				Thickness = theme.Stroke.thick,
			}),
			Icon = if props.icon
				then React.createElement(Icon, {
					name = props.icon,
					size = 22,
					color = fg,
					position = UDim2.new(0, layout.gap(14), 0.5, 0),
					anchorPoint = Vector2.new(0, 0.5),
				})
				else nil,
			Label = React.createElement("TextLabel", {
				Size = UDim2.new(1, if props.icon then -layout.px(42) else 0, 1, 0),
				Position = if props.icon then UDim2.fromOffset(layout.px(38), 0) else nil,
				BackgroundTransparency = 1,
				Text = props.text,
				TextSize = layout.text(14),
				Font = theme.Font.title,
				TextColor3 = fg,
			}),
		}),
	})
end

return OrnateButton
