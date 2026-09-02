--!strict
-- AAA signature: MeguminBlast (inspired by showcase-style Roblox explosion).
-- Story: charge circle → sky pillar → white-hot detonation → fire ring → ash.
-- Critical + denser High layers; Low still readable via core + shockwave.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local fire = TextureCatalog.FireBlast
local spark = TextureCatalog.SparkBurst
local smoke = TextureCatalog.SmokePuff
local ember = TextureCatalog.EmberTrail

local MeguminBlast: EffectDef = {
	id = "MeguminBlast",
	kind = "Burst",
	priority = "Critical",
	lifetime = 2.8,
	layers = {
		-- === CHARGE (magic circle feel) ===
		{ at = 0, type = "Sound", soundId = "vfx_charge", pitch = 0.65 },
		{ at = 0, type = "Haptic", hapticProfile = "Light", hapticStrength = 0.4 },
		{ at = 0, type = "CameraRumble", rumble = 0.055, roughness = 16, minTier = "Medium" },
		{
			at = 0,
			type = "Emit",
			count = 12,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			sizeScale = 0.35,
			speedMin = 0.8,
			speedMax = 2.5,
			lifetimeMin = 0.4,
			lifetimeMax = 0.7,
		},
		{ at = 0.05, type = "Shockwave", endSize = 4, duration = 0.45, minTier = "Medium" },
		{ at = 0.05, type = "Light", range = 14, brightness = 1.8, duration = 0.5, minTier = "Medium" },
		{ at = 0.1, type = "Beam", length = 28, width0 = 1.8, width1 = 0.1, duration = 0.45, minTier = "High" },

		-- === DETONATION ===
		{ at = 0.48, type = "Sound", soundId = "vfx_slam", pitch = 0.7 },
		{ at = 0.48, type = "Sound", soundId = "vfx_crit", pitch = 0.75 },
		{ at = 0.48, type = "Haptic", hapticProfile = "Heavy", hapticStrength = 1 },
		-- White-hot fire core
		{
			at = 0.48,
			type = "Emit",
			count = 56,
			texture = fire.id,
			flipbookLayout = fire.layout,
			flipbookMode = fire.mode,
			flipbookFpsMin = fire.fpsMin,
			flipbookFpsMax = fire.fpsMax,
			sizeScale = 2.0,
			speedMin = 10,
			speedMax = 28,
			minTier = "Medium",
		},
		-- Always-on debris (Low readable)
		{ at = 0.48, type = "Emit", count = 28, sizeScale = 0.7, speedMin = 12, speedMax = 32 },
		-- Sparks burst
		{
			at = 0.5,
			type = "Emit",
			count = 44,
			texture = spark.id,
			flipbookLayout = spark.layout,
			flipbookMode = spark.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = spark.fpsMin,
			flipbookFpsMax = spark.fpsMax,
			sizeScale = 1.0,
			speedMin = 18,
			speedMax = 42,
			lifetimeMin = 0.35,
			lifetimeMax = 0.8,
			minTier = "High",
		},
		-- Triple rings: punch → mid → wide
		{ at = 0.48, type = "Shockwave", endSize = 12, duration = 0.28 },
		{ at = 0.54, type = "Shockwave", endSize = 20, duration = 0.42, minTier = "Medium" },
		{ at = 0.62, type = "Shockwave", endSize = 30, duration = 0.6, minTier = "High" },
		{ at = 0.5, type = "Beam", length = 20, width0 = 2.8, minTier = "High" },
		{ at = 0.48, type = "Light", range = 42, brightness = 7.5, duration = 0.55 },
		{
			at = 0.48,
			type = "ScreenFlash",
			brightness = 0.38,
			duration = 0.2,
			blurSize = 14,
			minTier = "Medium",
		},
		{ at = 0.49, type = "CameraShake", shakeProfile = "Heavy", minTier = "Low" },

		-- === FIRE COLUMN / EMBER RAIN ===
		{
			at = 0.68,
			type = "Emit",
			count = 36,
			texture = ember.id,
			flipbookLayout = ember.layout,
			flipbookMode = ember.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = ember.fpsMin,
			flipbookFpsMax = ember.fpsMax,
			sizeScale = 0.85,
			speedMin = 5,
			speedMax = 16,
			lifetimeMin = 0.55,
			lifetimeMax = 1.1,
			minTier = "High",
		},
		{
			at = 0.7,
			type = "Emit",
			count = 20,
			texture = fire.id,
			flipbookLayout = fire.layout,
			flipbookMode = fire.mode,
			sizeScale = 1.2,
			speedMin = 3,
			speedMax = 10,
			minTier = "Ultra",
		},
		{ at = 0.72, type = "Light", range = 26, brightness = 3.2, duration = 0.65, minTier = "High" },

		-- === ASH / SMOKE RECOVERY ===
		{
			at = 1.15,
			type = "Emit",
			count = 28,
			texture = smoke.id,
			flipbookLayout = smoke.layout,
			flipbookMode = smoke.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = 8,
			flipbookFpsMax = 12,
			sizeScale = 1.8,
			speedMin = 0.3,
			speedMax = 2.0,
			lifetimeMin = 0.8,
			lifetimeMax = 1.4,
			minTier = "Medium",
		},
		{ at = 1.2, type = "Light", range = 12, brightness = 1.0, duration = 0.8, minTier = "High" },
		{
			at = 1.3,
			type = "Emit",
			count = 12,
			texture = ember.id,
			flipbookLayout = ember.layout,
			flipbookMode = ember.mode,
			flipbookStartRandom = true,
			sizeScale = 0.45,
			speedMin = 0.5,
			speedMax = 3,
			minTier = "High",
		},
	},
}

return MeguminBlast
