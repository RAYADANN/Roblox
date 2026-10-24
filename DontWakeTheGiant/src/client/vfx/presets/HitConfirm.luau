--!strict
-- Hit confirm на модели: Highlight + лёгкий emit. ctx.target = Model/BasePart.

local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local HitConfirm: EffectDef = {
    id = "HitConfirm",
    kind = "Burst",
    priority = "Medium",
    lifetime = 0.6,
    layers = {
        { at = 0, type = "Sound", soundId = "vfx_spark", pitch = 1.3 },
        { at = 0, type = "Haptic", hapticProfile = "Light" },
        { at = 0, type = "Highlight", duration = 0.2 },
        { at = 0, type = "Emit", count = 12 },
    },
}

return HitConfirm
