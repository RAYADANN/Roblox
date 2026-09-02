--!strict
-- Shared emit steps for body/surface impact (Workspace.Hit.Body attachment).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type LayerStep = LayerDef.LayerStep

local smoke = TextureCatalog.HitSmokeSoft
local sparks = TextureCatalog.HitSparksSky
local punch = TextureCatalog.HitPunchCore
local burst = TextureCatalog.HitBodyBurst

local HitBodyLayers = {}

function HitBodyLayers.visual(): { LayerStep }
    return {
        {
            at = 0,
            type = "Emit",
            count = 1,
            texture = punch.id,
            flipbookLayout = punch.layout,
            flipbookMode = punch.mode,
            flipbookFpsMin = punch.fpsMin,
            flipbookFpsMax = punch.fpsMax,
            emitStyle = "skyPunch",
            sizeScale = 1.35,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 0.85,
            lifetimeMax = 1.05,
            spread = 0,
            emitDuration = 1.2,
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
            sizeScale = 1.2,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 0.85,
            lifetimeMax = 1.05,
            spread = 0,
            emitDuration = 1.2,
        },
        {
            at = 0,
            type = "Emit",
            count = 1,
            texture = burst.id,
            flipbookLayout = burst.layout,
            flipbookMode = burst.mode,
            flipbookFpsMin = burst.fpsMin,
            flipbookFpsMax = burst.fpsMax,
            emitStyle = "skySparks",
            sizeScale = 1.25,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 0.85,
            lifetimeMax = 1.05,
            spread = 0,
            emitDuration = 1.2,
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
            sizeScale = 1.5,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 0.9,
            lifetimeMax = 1.1,
            spread = 0,
            emitDuration = 1.25,
            minTier = "Medium",
        },
        {
            at = 0,
            type = "Light",
            range = 9,
            brightness = 2.2,
            duration = 0.18,
            minTier = "Medium",
        },
    }
end

return HitBodyLayers
