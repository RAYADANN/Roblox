--!strict
-- Body impact (Workspace.Hit.Body): flesh hit = visuals + body SFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitBodyLayers = require(script.Parent.HitBodyLayers)
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local layers = HitBodyLayers.visual()
table.insert(layers, 1, { at = 0, type = "Sound", soundId = "hit_body", pitch = 1 })

local HitBody: EffectDef = {
    id = "HitBody",
    kind = "Burst",
    priority = "Medium",
    lifetime = 1.15,
    layers = layers,
}

return HitBody
