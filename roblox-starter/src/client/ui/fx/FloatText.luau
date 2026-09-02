--!strict
-- Generic floating text over the HUD. Per-game: text, color, start pos.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")

local theme = require(script.Parent.Parent.theme)
local FxOverlay = require(script.Parent.FxOverlay)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)

export type FloatTextOptions = {
	text: string,
	--- Absolute screen px (top-left origin). Default: center.
	position: Vector2?,
	color: Color3?,
	textSize: number?,
	font: Enum.Font?,
	duration: number?,
	risePx: number?,
	stroke: boolean?,
}

local FloatText = {}

local function toScale(abs: Vector2): UDim2
	local cam = workspace.CurrentCamera
	local inset = GuiService:GetGuiInset()
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local x = abs.X
	local y = abs.Y - inset.Y
	return UDim2.fromScale(x / vp.X, y / math.max(1, vp.Y))
end

function FloatText.play(opts: FloatTextOptions)
	local layer = FxOverlay.getLayer()
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local start = opts.position or Vector2.new(vp.X * 0.5, vp.Y * 0.45)
	local duration = opts.duration or 0.85
	local rise = opts.risePx or 56
	local reduce = SettingsManager.isReduceMotion()

	local label = Instance.new("TextLabel")
	label.Name = "FloatText"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = toScale(start)
	label.Size = UDim2.fromOffset(280, 40)
	label.Text = opts.text
	label.TextColor3 = opts.color or theme.Colors.gold
	label.Font = opts.font or theme.Font.heavy
	label.TextSize = opts.textSize or 22
	label.TextStrokeTransparency = if opts.stroke == false then 1 else 0.55
	label.TextStrokeColor3 = theme.Colors.outlineDark
	label.ZIndex = 20
	label.Parent = layer

	if reduce then
		label.TextTransparency = 0
		Debris:AddItem(label, math.min(duration, 0.45))
		return label
	end

	label.TextTransparency = 0.15
	label.Size = UDim2.fromOffset(240, 34)
	local pop = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local drift = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, pop, { Size = UDim2.fromOffset(280, 40), TextTransparency = 0 }):Play()
	local endPos = toScale(start - Vector2.new(0, rise))
	TweenService:Create(label, drift, {
		Position = endPos,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, duration + 0.05)
	return label
end

function FloatText.playNear(guiObject: GuiObject, opts: FloatTextOptions)
	local abs = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	local merged: FloatTextOptions = {
		text = opts.text,
		color = opts.color,
		textSize = opts.textSize,
		font = opts.font,
		duration = opts.duration,
		risePx = opts.risePx,
		stroke = opts.stroke,
		position = Vector2.new(abs.X + size.X * 0.5, abs.Y + size.Y * 0.2),
	}
	return FloatText.play(merged)
end

return FloatText
