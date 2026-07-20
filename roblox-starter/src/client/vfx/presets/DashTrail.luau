--!strict
local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local DashTrail: EffectDef = {
	id = "DashTrail",
	kind = "Burst",
	priority = "Medium",
	lifetime = 0.9,
	layers = {
		{ at = 0, type = "Emit", count = 18 },
		{ at = 0, type = "Beam", length = 10, minTier = "Medium" },
		{ at = 0, type = "Trail", duration = 0.35, width0 = 1.2, minTier = "Medium" },
		{ at = 0.05, type = "Emit", count = 10 },
		{ at = 0, type = "Light", range = 10, brightness = 1.6, minTier = "Medium" },
	},
}

return DashTrail
