--!strict
-- Снаряд: ctx.from + ctx.to. Impact на прибытии встроен в слой Projectile.

local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local NeonBolt: EffectDef = {
	id = "NeonBolt",
	kind = "Projectile",
	priority = "High",
	lifetime = 3,
	layers = {
		{ at = 0, type = "Projectile", count = 28, endSize = 7, speed = 110 },
		{ at = 0, type = "CameraShake", amplitude = 0.08, duration = 0.1, minTier = "High" },
	},
}

return NeonBolt
