--!strict
-- Signature Neon impact + sound/haptic. Anticipation → peak → recovery.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)
local StyleTokens = require(ReplicatedStorage.shared.vfx.StyleTokens)

export type EffectDef = LayerDef.EffectDef

local neon = TextureCatalog.NeonBurst
local spark = TextureCatalog.SparkBurst
local t = StyleTokens.timing

local NeonImpact: EffectDef = {
	id = "NeonImpact",
	kind = "Burst",
	priority = "High",
	lifetime = 1.55,
	layers = {
		{ at = t.anticipate, type = "Sound", soundId = "vfx_impact", pitch = 1.05 },
		{ at = t.flash, type = "Haptic", hapticProfile = "Heavy" },
		{
			at = t.anticipate,
			type = "Emit",
			count = 10,
			texture = neon.id,
			flipbookLayout = neon.layout,
			flipbookMode = neon.mode,
			flipbookStartRandom = false,
			flipbookFpsMin = neon.fpsMin,
			flipbookFpsMax = neon.fpsMax,
			sizeScale = 0.55,
			speedMin = 1.5,
			speedMax = 4,
			lifetimeMin = 0.2,
			lifetimeMax = 0.35,
		},
		{
			at = t.peak,
			type = "Emit",
			count = 42,
			texture = neon.id,
			flipbookLayout = neon.layout,
			flipbookMode = neon.mode,
			flipbookStartRandom = false,
			flipbookFpsMin = neon.fpsMin,
			flipbookFpsMax = neon.fpsMax,
			sizeScale = 1.35,
			speedMin = 6,
			speedMax = 16,
			minTier = "Medium",
		},
		{
			at = t.peak + 0.01,
			type = "Emit",
			count = 28,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = spark.fpsMin,
			flipbookFpsMax = spark.fpsMax,
			sizeScale = 0.7,
			speedMin = 12,
			speedMax = 28,
			lifetimeMin = 0.25,
			lifetimeMax = 0.55,
			minTier = "High",
		},
		{ at = t.peak, type = "Emit", count = 16, sizeScale = 0.45, speedMin = 8, speedMax = 22 },
		{ at = t.peak, type = "Shockwave", endSize = 13, duration = 0.4 },
		{ at = t.body, type = "Beam", length = 11, minTier = "Medium" },
		{ at = t.peak, type = "Light", range = 24, brightness = 4.4, duration = 0.38 },
		{
			at = t.peak,
			type = "ScreenFlash",
			brightness = 0.2,
			duration = 0.14,
			blurSize = 7,
			minTier = "High",
		},
		{ at = t.peak + 0.01, type = "CameraShake", shakeProfile = "Heavy", minTier = "Medium" },
		{
			at = t.recovery,
			type = "Emit",
			count = 12,
			texture = neon.id,
			flipbookLayout = neon.layout,
			flipbookMode = neon.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = 10,
			flipbookFpsMax = 14,
			sizeScale = 0.9,
			speedMin = 1,
			speedMax = 3.5,
			lifetimeMin = 0.4,
			lifetimeMax = 0.75,
			minTier = "High",
		},
		{ at = t.recovery + 0.02, type = "Light", range = 10, brightness = 1.2, duration = 0.45, minTier = "High" },
	},
}

return NeonImpact
