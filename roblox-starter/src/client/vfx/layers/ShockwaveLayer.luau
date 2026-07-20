--!strict
-- Expanding ring (Part + mesh). Дешёвый «wow»-слой для impact.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

export type ShockwaveConfig = {
	startSize: number?,
	endSize: number?,
	thickness: number?,
	duration: number?,
	transparency: number?,
}

local ShockwaveLayer = {}

function ShockwaveLayer.ring(parent: Instance, cframe: CFrame, color: Color3, config: ShockwaveConfig): Instance
	local startSize = config.startSize or 0.4
	local endSize = config.endSize or 10
	local thickness = config.thickness or 0.12
	local duration = config.duration or 0.35

	local ring = Instance.new("Part")
	ring.Name = "VfxShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Transparency = config.transparency or 0.25
	-- Cylinder: size X = height (thickness), YZ = diameter
	ring.Size = Vector3.new(thickness, startSize, startSize)
	ring.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = parent

	local info = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, {
		Size = Vector3.new(thickness * 0.4, endSize, endSize),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, duration + 0.05)
	return ring
end

return ShockwaveLayer
