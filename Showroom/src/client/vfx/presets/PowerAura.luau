--!strict
-- Aura / channel: Loop до handle:stop(). На Low тире enableLoops=false → не стартует.

local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local PowerAura: EffectDef = {
    id = "PowerAura",
    kind = "Loop",
    priority = "Medium",
    lifetime = nil,
    layers = {
        { at = 0, type = "LoopEmit", rate = 22 },
        {
            at = 0,
            type = "Light",
            range = 12,
            brightness = 1.2,
            duration = 0.4,
            minTier = "Medium",
        },
        { at = 0, type = "CameraRumble", rumble = 0.04, roughness = 14, minTier = "High" },
    },
}

return PowerAura
