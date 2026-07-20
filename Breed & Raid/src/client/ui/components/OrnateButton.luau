--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local UiSound = require(script.Parent.Parent.juice.UiSound)

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
}

local function colors(variant: Variant): (Color3, Color3, Color3)
	local C = theme.Colors
	-- Gold is bright → dark label; jade/primary/danger are deep → white label (AA).
	if variant == "gold" then
		return C.btnGold, C.textDark, C.goldDeep
	elseif variant == "jade" then
		return C.btnJade, C.white, C.success
	elseif variant == "sky" or variant == "primary" then
		return C.primary, C.white, C.primaryPressed
	elseif variant == "danger" then
		return C.btnDanger, C.white, C.danger
	end
	return C.btnGhost, C.textMain, C.outlineSoft
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
		Face = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = bg,
			BackgroundTransparency = if disabled then 0.4 else 0,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
			Stroke = React.createElement("UIStroke", {
				Color = stroke,
				Thickness = theme.Stroke.medium,
				Transparency = 0.1,
			}),
			Label = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
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
