--!strict
-- USP bullet tracer ribbon. Color from PlayContext.color (skin tracer RGB).

local LayerDef = require(game:GetService("ReplicatedStorage").shared.vfx.LayerDef)

export type EffectDef = LayerDef.EffectDef

local BulletTracer: EffectDef = {
    id = "BulletTracer",
    kind = "Burst",
    priority = "High",
    lifetime = 0.28,
    maxDistance = 500,
    layers = {
        -- width0 → FaceCamera Beam width; duration → fade (~50–150ms)
        { at = 0, type = "Tracer", width0 = 0.1, duration = 0.1 },
    },
}

return BulletTracer
