--!strict
-- Motion presets: Flipper springs + TweenInfo (from roblox-starter).

local TweenService = game:GetService("TweenService")

local MotionPresets = {}

local Spring = {
	snappy = { frequency = 6, dampingRatio = 0.85 },
	bouncy = { frequency = 4.5, dampingRatio = 0.62 },
	gentle = { frequency = 3, dampingRatio = 1 },
	number = { frequency = 4, dampingRatio = 1 },
	modal = { frequency = 5, dampingRatio = 0.78 },
}

local Tween = {
	hover = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	press = TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	fade = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	modalIn = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	modalOut = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	pop = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	slide = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	flash = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	ring = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local Scale = {
	hover = 1.06,
	press = 0.94,
	popPeak = 1.14,
	enter = 0.88,
}

MotionPresets.Spring = Spring
MotionPresets.Tween = Tween
MotionPresets.Scale = Scale

-- Compatibility aliases for current consumers.
MotionPresets.SPRING_SNAPPY = Spring.snappy
MotionPresets.SPRING_BOUNCY = Spring.bouncy
MotionPresets.SPRING_GENTLE = Spring.gentle
MotionPresets.SPRING_NUMBER = Spring.number
MotionPresets.HOVER = Tween.hover
MotionPresets.PRESS = Tween.press
MotionPresets.FADE = Tween.fade
MotionPresets.MODAL_IN = Tween.modalIn
MotionPresets.MODAL_OUT = Tween.modalOut
MotionPresets.POP = Tween.pop
MotionPresets.SLIDE = Tween.slide
MotionPresets.FLASH = Tween.flash
MotionPresets.RING = Tween.ring
MotionPresets.HOVER_SCALE = Scale.hover
MotionPresets.PRESS_SCALE = Scale.press
MotionPresets.POP_PEAK = Scale.popPeak

function MotionPresets.tween(instance: Instance, props: { [string]: any }, info: TweenInfo): Tween
	local tween = TweenService:Create(instance, info, props)
	tween:Play()
	return tween
end

function MotionPresets.fade(gui: GuiObject, target: number, info: TweenInfo?): Tween
	return MotionPresets.tween(gui, { BackgroundTransparency = target }, info or Tween.fade)
end

return MotionPresets
