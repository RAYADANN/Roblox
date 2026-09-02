--!strict
-- World/surface impact (floor, wall, props): same as Body attachment, no flesh SFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitBodyLayers = require(script.Parent.HitBodyLayers)
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local HitSurface: EffectDef = {
    id = "HitSurface",
    kind = "Burst",
    priority = "Low",
    lifetime = 1.15,
    layers = HitBodyLayers.visual(),
}

return HitSurface
