--!strict
-- Ultimate charge loop: rising intensity via handle:setIntensity.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local UltimateCharge: EffectDef = {
	id = "UltimateCharge",
	kind = "Loop",
	priority = "High",
	layers = {
		{ at = 0, type = "Sound", soundId = "vfx_charge", pitch = 0.9 },
		{ at = 0, type = "LoopEmit", rate = 28 },
		{ at = 0, type = "CameraRumble", rumble = 0.05, roughness = 20, minTier = "High" },
		{ at = 0.05, type = "Haptic", hapticProfile = "Light", hapticStrength = 0.3 },
	},
}

return UltimateCharge
