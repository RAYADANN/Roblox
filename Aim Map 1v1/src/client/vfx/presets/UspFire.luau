--!strict
-- Remote USP fire cue for clients other than the shooter (local plays via WeaponController).

local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local UspFire: EffectDef = {
    id = "UspFire",
    kind = "Burst",
    priority = "High",
    lifetime = 0.35,
    layers = {
        { at = 0, type = "Sound", soundId = "usp_fire", pitch = 1 },
    },
}

return UspFire
