--!strict
-- Signature Smoke dash: dense puff flipbook + trail + residual sparks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local tex = TextureCatalog.SmokePuff

local SmokeDash: EffectDef = {
	id = "SmokeDash",
	kind = "Burst",
	priority = "High",
	lifetime = 1.2,
	layers = {
		{
			at = 0,
			type = "Emit",
			count = 28,
			texture = tex.id,
			flipbookLayout = tex.layout,
			flipbookMode = tex.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = tex.fpsMin,
			flipbookFpsMax = tex.fpsMax,
			minTier = "Medium",
		},
		{ at = 0, type = "Trail", duration = 0.45, width0 = 1.6, minTier = "Medium" },
		{ at = 0.04, type = "Emit", count = 14 },
		{ at = 0.02, type = "Beam", length = 8, minTier = "High" },
		{ at = 0, type = "Light", range = 12, brightness = 1.4, duration = 0.25, minTier = "Medium" },
		{ at = 0.03, type = "CameraShake", amplitude = 0.1, duration = 0.12, minTier = "High" },
	},
}

return SmokeDash
