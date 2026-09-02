--!strict
-- Expanding ring. Пул Part'ов.

local TweenService = game:GetService("TweenService")
local InstancePool = require(script.Parent.Parent.InstancePool)

export type ShockwaveConfig = {
	startSize: number?,
	endSize: number?,
	thickness: number?,
	duration: number?,
	transparency: number?,
}

local ShockwaveLayer = {}

local _pool: InstancePool.InstancePool? = nil

local function ensurePool(parent: Instance): InstancePool.InstancePool
	if _pool then
		return _pool
	end
	_pool = InstancePool.new({
		name = "VfxShockwave",
		maxSize = 24,
		parent = parent,
		factory = function()
			local ring = Instance.new("Part")
			ring.Name = "VfxShockwave"
			ring.Shape = Enum.PartType.Cylinder
			ring.Material = Enum.Material.Neon
			ring.Anchored = true
			ring.CanCollide = false
			ring.CanQuery = false
			ring.CanTouch = false
			ring.CastShadow = false
			return ring
		end,
		reset = function(inst)
			if inst:IsA("BasePart") then
				inst.Transparency = 1
				inst.Size = Vector3.new(0.1, 0.1, 0.1)
			end
		end,
	})
	_pool:prewarm(4)
	return _pool
end

function ShockwaveLayer.ring(parent: Instance, cframe: CFrame, color: Color3, config: ShockwaveConfig): Instance
	local startSize = config.startSize or 0.4
	local endSize = config.endSize or 10
	local thickness = config.thickness or 0.12
	local duration = config.duration or 0.35

	local pool = ensurePool(parent)
	local ring = pool:take() :: BasePart
	ring.Color = color
	ring.Transparency = config.transparency or 0.25
	ring.Size = Vector3.new(thickness, startSize, startSize)
	ring.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = parent

	local info = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, {
		Size = Vector3.new(thickness * 0.4, endSize, endSize),
		Transparency = 1,
	}):Play()
	task.delay(duration + 0.05, function()
		if ring.Parent then
			pool:give(ring)
		end
	end)
	return ring
end

return ShockwaveLayer
