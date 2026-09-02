--!strict
-- Multi-point chain along from→to (readable arc hits).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local spark = TextureCatalog.SparkBurst

local ChainStrike: EffectDef = {
	id = "ChainStrike",
	kind = "Chain",
	priority = "High",
	lifetime = 1.4,
	layers = {
		{ at = 0, type = "Sound", soundId = "vfx_spark", pitch = 1.2 },
		{ at = 0.02, type = "Haptic", hapticProfile = "Medium" },
		-- Runner "ChainEmit" expands along from/to
		{
			at = 0,
			type = "ChainEmit",
			count = 14,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = spark.fpsMin,
			flipbookFpsMax = spark.fpsMax,
			sizeScale = 0.55,
			speedMin = 2,
			speedMax = 8,
		},
		{ at = 0.05, type = "Beam", length = 10, minTier = "Medium" },
		{ at = 0.08, type = "CameraShake", shakeProfile = "Medium", minTier = "Medium" },
		{ at = 0.1, type = "Light", range = 14, brightness = 2.8, duration = 0.25, minTier = "Medium" },
	},
}

return ChainStrike
