--!strict
-- Signature Neon impact: flipbook core + shockwave + beam + light + shake.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local tex = TextureCatalog.NeonBurst

local NeonImpact: EffectDef = {
	id = "NeonImpact",
	kind = "Burst",
	priority = "High",
	lifetime = 1.35,
	layers = {
		{
			at = 0,
			type = "Emit",
			count = 34,
			texture = tex.id,
			flipbookLayout = tex.layout,
			flipbookMode = tex.mode,
			flipbookStartRandom = false,
			flipbookFpsMin = tex.fpsMin,
			flipbookFpsMax = tex.fpsMax,
			minTier = "Medium",
		},
		{ at = 0, type = "Emit", count = 18 },
		{ at = 0, type = "Shockwave", endSize = 11 },
		{ at = 0.02, type = "Beam", length = 9, minTier = "Medium" },
		{ at = 0.03, type = "Light", range = 20, brightness = 3.8, duration = 0.32 },
		{
			at = 0,
			type = "ScreenFlash",
			brightness = 0.14,
			duration = 0.12,
			blurSize = 5,
			minTier = "High",
		},
		{
			at = 0.04,
			type = "CameraShake",
			amplitude = 0.2,
			duration = 0.18,
			roughness = 30,
			minTier = "Medium",
		},
	},
}

return NeonImpact
