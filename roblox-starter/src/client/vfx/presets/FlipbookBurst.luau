--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local tex = TextureCatalog.NeonBurst

local FlipbookBurst: EffectDef = {
	id = "FlipbookBurst",
	kind = "Burst",
	priority = "High",
	lifetime = 1.1,
	layers = {
		{
			at = 0,
			type = "Emit",
			count = 28,
			texture = tex.id,
			flipbookLayout = tex.layout,
			flipbookMode = tex.mode,
			flipbookStartRandom = false,
			flipbookFpsMin = tex.fpsMin,
			flipbookFpsMax = tex.fpsMax,
			minTier = "Medium",
		},
		{ at = 0, type = "Shockwave", endSize = 9 },
		{ at = 0.02, type = "Light", range = 18, brightness = 3.2, minTier = "Medium" },
		{ at = 0.03, type = "CameraShake", amplitude = 0.12, duration = 0.14, minTier = "High" },
	},
}

return FlipbookBurst
