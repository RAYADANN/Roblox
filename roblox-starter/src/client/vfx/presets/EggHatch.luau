--!strict
-- Content signature: egg hatch (gacha / egg loop).
-- Crack anticipation → shell burst → reveal sparkles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local neon = TextureCatalog.NeonBurst
local spark = TextureCatalog.SparkBurst
local smoke = TextureCatalog.SmokePuff

local EggHatch: EffectDef = {
	id = "EggHatch",
	kind = "Burst",
	priority = "High",
	lifetime = 2.0,
	layers = {
		-- Crack wind-up
		{ at = 0, type = "Sound", soundId = "vfx_charge", pitch = 1.2 },
		{ at = 0, type = "Haptic", hapticProfile = "Light", hapticStrength = 0.4 },
		{ at = 0, type = "CameraRumble", rumble = 0.035, roughness = 22, minTier = "Medium" },
		{
			at = 0.05,
			type = "Emit",
			count = 8,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			sizeScale = 0.35,
			speedMin = 1,
			speedMax = 3,
		},
		{ at = 0.08, type = "Light", range = 8, brightness = 1.4, duration = 0.35, minTier = "Medium" },

		-- Shell burst
		{ at = 0.42, type = "Sound", soundId = "vfx_crit", pitch = 1.15 },
		{ at = 0.42, type = "Haptic", hapticProfile = "Heavy", hapticStrength = 0.75 },
		{ at = 0.42, type = "Emit", count = 18, sizeScale = 0.55, speedMin = 10, speedMax = 24 },
		{
			at = 0.42,
			type = "Emit",
			count = 28,
			texture = neon.id,
			flipbookLayout = neon.layout,
			flipbookMode = neon.mode,
			flipbookFpsMin = neon.fpsMin,
			flipbookFpsMax = neon.fpsMax,
			sizeScale = 1.25,
			speedMin = 6,
			speedMax = 18,
			minTier = "Medium",
		},
		{
			at = 0.44,
			type = "Emit",
			count = 24,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			sizeScale = 0.7,
			speedMin = 8,
			speedMax = 22,
			minTier = "High",
		},
		{ at = 0.42, type = "Shockwave", endSize = 11, duration = 0.4 },
		{ at = 0.45, type = "Beam", length = 10, minTier = "High" },
		{ at = 0.42, type = "Light", range = 22, brightness = 4.2, duration = 0.4 },
		{
			at = 0.42,
			type = "ScreenFlash",
			brightness = 0.18,
			duration = 0.16,
			blurSize = 8,
			minTier = "Medium",
		},
		{ at = 0.43, type = "CameraShake", shakeProfile = "Heavy", minTier = "Medium" },

		-- Reveal glitter + soft haze
		{
			at = 0.7,
			type = "Emit",
			count = 16,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			sizeScale = 0.5,
			speedMin = 1,
			speedMax = 5,
			minTier = "High",
		},
		{
			at = 0.75,
			type = "Emit",
			count = 10,
			texture = smoke.id,
			flipbookLayout = smoke.layout,
			flipbookMode = smoke.mode,
			flipbookStartRandom = true,
			sizeScale = 1.0,
			speedMin = 0.3,
			speedMax = 1.8,
			minTier = "Medium",
		},
		{ at = 0.72, type = "Light", range = 12, brightness = 1.6, duration = 0.55, minTier = "High" },
		{ at = 0.42, type = "Highlight", duration = 0.5, fillTransparency = 0.4, minTier = "High" },
	},
}

return EggHatch
