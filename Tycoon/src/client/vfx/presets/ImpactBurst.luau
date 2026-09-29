--!strict
local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local ImpactBurst: EffectDef = {
    id = "ImpactBurst",
    kind = "Burst",
    priority = "High",
    lifetime = 1.2,
    layers = {
        { at = 0, type = "Sound", soundId = "vfx_impact" },
        { at = 0.02, type = "Haptic", hapticProfile = "Medium" },
        { at = 0, type = "Emit", count = 36 },
        { at = 0, type = "Shockwave", endSize = 8 },
        { at = 0.02, type = "Beam", length = 7, minTier = "Medium" },
        { at = 0.04, type = "Light", range = 16, brightness = 3 },
        {
            at = 0,
            type = "ScreenFlash",
            brightness = 0.12,
            duration = 0.12,
            blurSize = 4,
            minTier = "High",
        },
        { at = 0.03, type = "CameraShake", shakeProfile = "Medium", minTier = "Medium" },
    },
}

return ImpactBurst
