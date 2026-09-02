--!strict
local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local CastBurst: EffectDef = {
	id = "CastBurst",
	kind = "Burst",
	priority = "High",
	lifetime = 1.5,
	layers = {
		{ at = 0, type = "Sound", soundId = "vfx_cast", pitch = 1.05 },
		{ at = 0.08, type = "Haptic", hapticProfile = "Medium" },
		{ at = 0, type = "Emit", count = 8 },
		{ at = 0.08, type = "Emit", count = 40 },
		{ at = 0.08, type = "Shockwave", endSize = 12 },
		{ at = 0.08, type = "Beam", length = 12, minTier = "Medium" },
		{ at = 0.08, type = "Light", range = 20, brightness = 4 },
		{ at = 0.08, type = "ScreenFlash", brightness = 0.16, duration = 0.14, blurSize = 8, minTier = "High" },
		{ at = 0.1, type = "CameraShake", shakeProfile = "Heavy", minTier = "Medium" },
	},
}

return CastBurst
