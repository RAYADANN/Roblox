--!strict
-- Chunky 3D sim icon button (gradient + dark lip) — reference pet-sim style.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local UiSound = require(script.Parent.Parent.juice.UiSound)
local Icon = require(script.Parent.Icon)

export type Tone = "blue" | "orange" | "cyan" | "red" | "green" | "purple" | "yellow" | "wood"

export type Props = {
	label: string,
	icon: string, -- emoji / glyph fallback
	image: string?, -- rbxassetid:// optional
	iconName: string?, -- centralized registry name; icon remains fallback
	tone: Tone?,
	active: boolean?,
	layoutOrder: number?,
	size: number?, -- design px square
	showLabel: boolean?,
	onClick: () -> (),
}

local TONES: { [Tone]: { top: Color3, bot: Color3, lip: Color3 } } = {
	blue = {
		top = theme.Action.primaryHighlight,
		bot = theme.Action.primary,
		lip = theme.Action.primaryShadow,
	},
	orange = {
		top = theme.Action.rewardHighlight,
		bot = theme.Semantic.warning,
		lip = theme.Action.rewardShadow,
	},
	cyan = {
		top = Color3.fromRGB(102, 226, 239),
		bot = Color3.fromRGB(39, 180, 207),
		lip = Color3.fromRGB(22, 112, 145),
	},
	red = {
		top = theme.Action.dangerHighlight,
		bot = theme.Action.danger,
		lip = theme.Action.dangerShadow,
	},
	green = {
		top = theme.Action.collectHighlight,
		bot = theme.Action.collect,
		lip = theme.Action.collectShadow,
	},
	purple = {
		top = theme.Action.breedHighlight,
		bot = theme.Action.breed,
		lip = theme.Action.breedShadow,
	},
	yellow = {
		top = theme.Action.rewardHighlight,
		bot = theme.Action.reward,
		lip = theme.Action.rewardShadow,
	},
	wood = {
		top = Color3.fromRGB(210, 160, 100),
		bot = Color3.fromRGB(150, 100, 55),
		lip = Color3.fromRGB(90, 55, 25),
	},
}

local function SimIconButton(props: Props): React.Node
	local layout = useLayout()
	local tone = props.tone or "blue"
	local colors = TONES[tone]
	local scale, handlers = useHoverPress({})
	local size = layout.touch(props.size or theme.Design.NAV_BTN)
	local showLabel = props.showLabel ~= false
	local lip = layout.px(5)
	local active = props.active == true

	return React.createElement("TextButton", {
		Size = UDim2.fromOffset(size, if showLabel then size + layout.px(18) else size),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = function()
			UiSound.play("click")
			props.onClick()
		end,
		[React.Event.MouseEnter] = handlers.onMouseEnter,
		[React.Event.MouseLeave] = handlers.onMouseLeave,
		[React.Event.MouseButton1Down] = handlers.onMouseDown,
		[React.Event.MouseButton1Up] = handlers.onMouseUp,
	}, {
		Scale = React.createElement("UIScale", { Scale = scale }),
		Lip = React.createElement("Frame", {
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromOffset(0, lip),
			BackgroundColor3 = colors.lip,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.md }),
		}),
		Face = React.createElement("Frame", {
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = colors.bot,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.md }),
			Grad = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, colors.top),
					ColorSequenceKeypoint.new(1, colors.bot),
				}),
				Rotation = 90,
			}),
			Stroke = React.createElement("UIStroke", {
				Color = if active then theme.Border.light else colors.lip,
				Thickness = if active then 3 else 2,
				Transparency = if active then 0 else 0.25,
			}),
			Shine = React.createElement("Frame", {
				Size = UDim2.new(1, -layout.px(10), 0, layout.px(8)),
				Position = UDim2.fromOffset(layout.px(5), layout.px(5)),
				BackgroundColor3 = theme.Border.light,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.sm }),
			}),
			Icon = if props.image
				then React.createElement("ImageLabel", {
					Size = UDim2.fromOffset(layout.px(40), layout.px(40)),
					Position = UDim2.new(0.5, 0, 0.5, -layout.px(2)),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = props.image,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 4,
				})
				elseif props.iconName
				then React.createElement(Icon, {
					name = props.iconName,
					size = 40,
					color = theme.Content.inverse,
					position = UDim2.new(0.5, 0, 0.5, -layout.px(2)),
					anchorPoint = Vector2.new(0.5, 0.5),
					zIndex = 4,
				})
				else React.createElement("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = props.icon,
					TextSize = layout.text(28),
					Font = theme.Font.heavy,
					TextColor3 = theme.Content.inverse,
					ZIndex = 4,
				}),
		}),
		Caption = if showLabel
			then React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, layout.px(16)),
				Position = UDim2.new(0, 0, 1, -layout.px(14)),
				BackgroundTransparency = 1,
				Text = props.label,
				TextSize = layout.text(11),
				Font = theme.Font.heavy,
				TextColor3 = theme.Content.inverse,
				TextStrokeTransparency = 0.4,
				TextStrokeColor3 = theme.Action.neutralShadow,
				ZIndex = 5,
			})
			else nil,
	})
end

return SimIconButton
