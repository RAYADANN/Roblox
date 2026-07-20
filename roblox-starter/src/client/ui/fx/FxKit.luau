--!strict
-- Примитивы FX. Копируй в момент-эффекты. См. fx.mdc.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)

local FxKit = {}

function FxKit.shockwave(parent: Instance, color: Color3, size: number, duration: number?)
	local dur = duration or 0.4
	local ring = Instance.new("Frame")
	ring.Name = "Shockwave"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(8, 8)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 10
	ring.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Transparency = 0.2
	stroke.Parent = ring

	local info = TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(size, size) }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	Debris:AddItem(ring, dur + 0.1)
end

return FxKit
