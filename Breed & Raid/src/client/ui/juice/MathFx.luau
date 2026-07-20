--!strict
-- Math/Frame one-shot FX (no particles). Parent under a ScreenGui/frame.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)

local MathFx = {}

function MathFx.shockwave(parent: GuiObject, color: Color3, sizePx: number, duration: number?)
	local dur = duration or 0.4
	local ring = Instance.new("Frame")
	ring.Name = "Shockwave"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(10, 10)
	ring.BackgroundTransparency = 1
	ring.ZIndex = (parent.ZIndex or 1) + 5
	ring.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Transparency = 0.15
	stroke.Parent = ring

	local info = TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(sizePx, sizePx) }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	Debris:AddItem(ring, dur + 0.05)
end

function MathFx.goldFlash(parent: GuiObject)
	local flash = Instance.new("Frame")
	flash.Name = "GoldFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = theme.Colors.goldHi
	flash.BackgroundTransparency = 0.55
	flash.BorderSizePixel = 0
	flash.ZIndex = (parent.ZIndex or 1) + 20
	flash.Parent = parent

	TweenService:Create(flash, MotionPresets.FLASH, { BackgroundTransparency = 1 }):Play()
	Debris:AddItem(flash, 0.5)
end

function MathFx.burstDots(parent: GuiObject, color: Color3, count: number?)
	local n = count or 8
	for i = 1, n do
		local angle = (i / n) * math.pi * 2
		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(8, 8)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.ZIndex = (parent.ZIndex or 1) + 6
		dot.Parent = parent
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = dot
		local dist = 0.12 + (i % 3) * 0.04
		local target = UDim2.fromScale(0.5 + math.cos(angle) * dist, 0.5 + math.sin(angle) * dist)
		TweenService:Create(dot, MotionPresets.POP, {
			Position = target,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(2, 2),
		}):Play()
		Debris:AddItem(dot, 0.4)
	end
end

function MathFx.confetti(parent: GuiObject, count: number?)
	local n = count or 28
	local palette = {
		Color3.fromRGB(255, 90, 200),
		Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(80, 180, 255),
		Color3.fromRGB(120, 255, 160),
		Color3.fromRGB(180, 100, 255),
		Color3.fromRGB(255, 120, 80),
	}
	for i = 1, n do
		local bit = Instance.new("Frame")
		local w = 6 + (i % 4) * 2
		local h = 8 + (i % 3) * 3
		bit.Size = UDim2.fromOffset(w, h)
		bit.AnchorPoint = Vector2.new(0.5, 0.5)
		bit.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.15, 0.42)
		bit.BackgroundColor3 = palette[((i - 1) % #palette) + 1]
		bit.Rotation = math.random(0, 360)
		bit.BorderSizePixel = 0
		bit.ZIndex = (parent.ZIndex or 1) + 8
		bit.Parent = parent
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 2)
		corner.Parent = bit
		local dx = (math.random() - 0.5) * 0.7
		local dy = 0.35 + math.random() * 0.45
		local dur = 0.7 + math.random() * 0.35
		TweenService:Create(
			bit,
			TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromScale(0.5 + dx, 0.5 + dy),
				Rotation = bit.Rotation + math.random(-120, 120),
				BackgroundTransparency = 1,
			}
		):Play()
		Debris:AddItem(bit, dur + 0.05)
	end
end

function MathFx.auraPulse(parent: GuiObject, color: Color3)
	local glow = Instance.new("Frame")
	glow.Name = "Aura"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.48)
	glow.Size = UDim2.fromOffset(40, 40)
	glow.BackgroundColor3 = color
	glow.BackgroundTransparency = 0.35
	glow.BorderSizePixel = 0
	glow.ZIndex = (parent.ZIndex or 1) + 2
	glow.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = glow
	local info = TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(glow, info, {
		Size = UDim2.fromOffset(280, 280),
		BackgroundTransparency = 1,
	}):Play()
	Debris:AddItem(glow, 0.9)
end

return MathFx
