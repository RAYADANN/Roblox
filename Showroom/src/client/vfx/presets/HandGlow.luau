--!strict
-- Attached к BasePart (рука/оружие). ctx.target обязателен.

local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local HandGlow: EffectDef = {
    id = "HandGlow",
    kind = "Attached",
    priority = "Medium",
    lifetime = nil,
    layers = {
        { at = 0, type = "AttachedEmit", rate = 14 },
    },
}

return HandGlow
