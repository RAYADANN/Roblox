--!strict
-- Headshot impact (Workspace.Hit.Head): larger sky–primary flipbooks + head SFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local smoke = TextureCatalog.HitSmokeSoft
local sparks = TextureCatalog.HitSparksSky
local punch = TextureCatalog.HitPunchCore

local HitHead: EffectDef = {
    id = "HitHead",
    kind = "Burst",
    priority = "High",
    lifetime = 1.35,
    layers = {
        { at = 0, type = "Sound", soundId = "hit_head", pitch = 1 },
        {
            at = 0,
            type = "Emit",
            count = 2,
            texture = punch.id,
            flipbookLayout = punch.layout,
            flipbookMode = punch.mode,
            flipbookFpsMin = punch.fpsMin,
            flipbookFpsMax = punch.fpsMax,
            emitStyle = "skyPunch",
            sizeScale = 4.2,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 0.9,
            lifetimeMax = 1.1,
            spread = 0,
            emitDuration = 1.3,
        },
        {
            at = 0,
            type = "Emit",
            count = 1,
            texture = sparks.id,
            flipbookLayout = sparks.layout,
            flipbookMode = sparks.mode,
            flipbookFpsMin = sparks.fpsMin,
            flipbookFpsMax = sparks.fpsMax,
            emitStyle = "skySparks",
            sizeScale = 4.0,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 0.9,
            lifetimeMax = 1.1,
            spread = 0,
            emitDuration = 1.3,
        },
        {
            at = 0.02,
            type = "Emit",
            count = 1,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookFpsMin = smoke.fpsMin,
            flipbookFpsMax = smoke.fpsMax,
            emitStyle = "skyCombat",
            sizeScale = 4.5,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 0.95,
            lifetimeMax = 1.15,
            spread = 0,
            emitDuration = 1.35,
            minTier = "Medium",
        },
        {
            at = 0,
            type = "Light",
            range = 14,
            brightness = 3.4,
            duration = 0.24,
            minTier = "Medium",
        },
    },
}

return HitHead
