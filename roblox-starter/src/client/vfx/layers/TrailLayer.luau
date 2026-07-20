--!strict
-- Слой Trail на Part (движение → шлейф). Для Dash / Projectile.

local Debris = game:GetService("Debris")
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type TrailConfig = {
	lifetime: number?,
	minLength: number?,
	width0: number?,
	width1: number?,
	duration: number?,
}

local TrailLayer = {}

function TrailLayer.attach(
	anchor: BasePart,
	color: Color3,
	config: TrailConfig,
	budget: QualityBudget
): Trail?
	if not budget.enableTrails then
		return nil
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "VfxTrail0"
	a0.Position = Vector3.new(0, 0.15, 0)
	a0.Parent = anchor
	local a1 = Instance.new("Attachment")
	a1.Name = "VfxTrail1"
	a1.Position = Vector3.new(0, -0.15, 0)
	a1.Parent = anchor

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new(0.15, 1)
	trail.Lifetime = config.lifetime or 0.35
	trail.MinLength = config.minLength or 0.05
	trail.FaceCamera = true
	trail.LightEmission = 0.7
	trail.WidthScale = NumberSequence.new(config.width0 or 1, config.width1 or 0)
	trail.Parent = anchor

	local duration = config.duration
	if duration then
		task.delay(duration, function()
			trail.Enabled = false
		end)
		Debris:AddItem(a0, duration + (config.lifetime or 0.35) + 0.05)
		Debris:AddItem(a1, duration + (config.lifetime or 0.35) + 0.05)
		Debris:AddItem(trail, duration + (config.lifetime or 0.35) + 0.05)
	end

	return trail
end

return TrailLayer
