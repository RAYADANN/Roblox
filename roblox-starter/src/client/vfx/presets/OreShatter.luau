--!strict
-- Content signature: ore break (mining loop).
-- Rock chips + mineral spark + short punch — readable every swing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local spark = TextureCatalog.SparkBurst
local smoke = TextureCatalog.SmokePuff
local ember = TextureCatalog.EmberTrail

local OreShatter: EffectDef = {
	id = "OreShatter",
	kind = "Burst",
	priority = "High",
	lifetime = 1.15,
	layers = {
		{ at = 0, type = "Sound", soundId = "vfx_impact", pitch = 1.35 },
		{ at = 0.02, type = "Haptic", hapticProfile = "Medium" },
		-- Rock chips (cheap, always)
		{ at = 0, type = "Emit", count = 20, sizeScale = 0.5, speedMin = 8, speedMax = 20, lifetimeMin = 0.25, lifetimeMax = 0.5 },
		-- Mineral flash
		{
			at = 0.02,
			type = "Emit",
			count = 16,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = spark.fpsMin,
			flipbookFpsMax = spark.fpsMax,
			sizeScale = 0.55,
			speedMin = 6,
			speedMax = 16,
			minTier = "Medium",
		},
		-- Dust puff
		{
			at = 0.04,
			type = "Emit",
			count = 12,
			texture = smoke.id,
			flipbookLayout = smoke.layout,
			flipbookMode = smoke.mode,
			flipbookStartRandom = true,
			sizeScale = 0.8,
			speedMin = 1,
			speedMax = 4,
			minTier = "Medium",
		},
		-- Rare vein glint (High+)
		{
			at = 0.05,
			type = "Emit",
			count = 8,
			texture = ember.id,
			flipbookLayout = ember.layout,
			flipbookMode = ember.mode,
			flipbookStartRandom = true,
			sizeScale = 0.4,
			speedMin = 4,
			speedMax = 10,
			minTier = "High",
		},
		{ at = 0.02, type = "Shockwave", endSize = 5, duration = 0.22 },
		{ at = 0.02, type = "Light", range = 10, brightness = 2.2, duration = 0.18 },
		{ at = 0.03, type = "CameraShake", shakeProfile = "Light", minTier = "Medium" },
		{ at = 0.04, type = "Beam", length = 4, minTier = "High" },
	},
}

return OreShatter
