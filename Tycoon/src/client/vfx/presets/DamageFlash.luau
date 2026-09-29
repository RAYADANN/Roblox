--!strict
-- Только экран: hit confirm / damage flash. Не требует world cframe.

local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local DamageFlash: EffectDef = {
    id = "DamageFlash",
    kind = "Screen",
    priority = "High",
    lifetime = 0.5,
    maxDistance = 1e9,
    layers = {
        { at = 0, type = "ScreenFlash", brightness = 0.22, duration = 0.18, blurSize = 12 },
        {
            at = 0,
            type = "CameraShake",
            amplitude = 0.22,
            duration = 0.2,
            roughness = 40,
            minTier = "Medium",
        },
    },
}

return DamageFlash
