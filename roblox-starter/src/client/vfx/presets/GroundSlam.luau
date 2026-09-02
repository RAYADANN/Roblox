--!strict
-- Ground slam: vertical read + wide shockwave.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)
local StyleTokens = require(ReplicatedStorage.shared.vfx.StyleTokens)

export type EffectDef = LayerDef.EffectDef

local smoke = TextureCatalog.SmokePuff
local ember = TextureCatalog.EmberTrail
local t = StyleTokens.timing

local GroundSlam: EffectDef = {
	id = "GroundSlam",
	kind = "Burst",
	priority = "High",
	lifetime = 1.6,
	layers = {
		{ at = 0, type = "Sound", soundId = "vfx_slam" },
		{ at = 0.02, type = "Haptic", hapticProfile = "Heavy" },
		{ at = 0, type = "Emit", count = 12, sizeScale = 0.5, speedMin = 2, speedMax = 6 },
		{
			at = t.peak,
			type = "Emit",
			count = 32,
			texture = smoke.id,
			flipbookLayout = smoke.layout,
			flipbookMode = smoke.mode,
			flipbookStartRandom = true,
			flipbookFpsMin = smoke.fpsMin,
			flipbookFpsMax = smoke.fpsMax,
			sizeScale = 1.5,
			speedMin = 3,
			speedMax = 10,
			minTier = "Medium",
		},
		{
			at = t.peak,
			type = "Emit",
			count = 20,
			texture = ember.id,
			flipbookLayout = ember.layout,
			flipbookMode = ember.mode,
			flipbookStartRandom = true,
			sizeScale = 0.6,
			speedMin = 8,
			speedMax = 18,
			minTier = "High",
		},
		{ at = t.peak, type = "Shockwave", endSize = 18, duration = 0.5 },
		{ at = t.body, type = "Beam", length = 6, minTier = "High" },
		{ at = t.peak, type = "Light", range = 22, brightness = 3.5, duration = 0.4 },
		{ at = t.peak, type = "ScreenFlash", brightness = 0.14, duration = 0.12, blurSize = 6, minTier = "High" },
		{ at = t.peak + 0.02, type = "CameraShake", shakeProfile = "Heavy", minTier = "Medium" },
	},
}

return GroundSlam
