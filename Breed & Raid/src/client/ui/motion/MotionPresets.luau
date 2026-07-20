--!strict
-- Motion presets: Flipper springs + TweenInfo (from roblox-starter).

local TweenService = game:GetService("TweenService")

local MotionPresets = {}

MotionPresets.SPRING_SNAPPY = { frequency = 6, dampingRatio = 0.85 }
MotionPresets.SPRING_BOUNCY = { frequency = 4.5, dampingRatio = 0.62 }
MotionPresets.SPRING_GENTLE = { frequency = 3, dampingRatio = 1 }
MotionPresets.SPRING_NUMBER = { frequency = 4, dampingRatio = 1 }

MotionPresets.HOVER = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
MotionPresets.PRESS = TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
MotionPresets.FADE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
MotionPresets.MODAL_IN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
MotionPresets.MODAL_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
MotionPresets.POP = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
MotionPresets.SLIDE = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
MotionPresets.FLASH = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
MotionPresets.RING = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

MotionPresets.HOVER_SCALE = 1.06
MotionPresets.PRESS_SCALE = 0.94
MotionPresets.POP_PEAK = 1.14

function MotionPresets.tween(instance: Instance, props: { [string]: any }, info: TweenInfo): Tween
	local tween = TweenService:Create(instance, info, props)
	tween:Play()
	return tween
end

return MotionPresets
