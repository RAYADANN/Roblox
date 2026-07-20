--!strict
local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local CastBurst: EffectDef = {
	id = "CastBurst",
	kind = "Burst",
	priority = "High",
	lifetime = 1.5,
	layers = {
		{ at = 0, type = "Emit", count = 8 },
		{ at = 0.08, type = "Emit", count = 40 },
		{ at = 0.08, type = "Shockwave", endSize = 12 },
		{ at = 0.08, type = "Beam", length = 12, minTier = "Medium" },
		{ at = 0.08, type = "Light", range = 20, brightness = 4 },
		{ at = 0.08, type = "ScreenFlash", brightness = 0.16, duration = 0.14, blurSize = 8, minTier = "High" },
		{ at = 0.1, type = "CameraShake", amplitude = 0.28, duration = 0.2, roughness = 32, minTier = "Medium" },
	},
}

return CastBurst
