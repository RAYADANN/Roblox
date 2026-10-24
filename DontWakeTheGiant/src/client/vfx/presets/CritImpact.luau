--!strict
-- Crit impact: denser + Critical priority (пробивает soft-cap).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local StyleTokens = require(ReplicatedStorage.shared.vfx.StyleTokens)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local neon = TextureCatalog.NeonBurst
local spark = TextureCatalog.SparkBurst
local t = StyleTokens.timing

local CritImpact: EffectDef = {
    id = "CritImpact",
    kind = "Burst",
    priority = "Critical",
    lifetime = 1.7,
    layers = {
        { at = 0, type = "Sound", soundId = "vfx_crit", pitch = 0.95 },
        { at = 0.02, type = "Haptic", hapticProfile = "Heavy", hapticStrength = 1 },
        {
            at = 0,
            type = "Emit",
            count = 14,
            texture = neon.id,
            flipbookLayout = neon.layout,
            flipbookMode = neon.mode,
            flipbookFpsMin = neon.fpsMin,
            flipbookFpsMax = neon.fpsMax,
            sizeScale = 0.6,
            speedMin = 2,
            speedMax = 5,
        },
        {
            at = t.peak,
            type = "Emit",
            count = 56,
            texture = neon.id,
            flipbookLayout = neon.layout,
            flipbookMode = neon.mode,
            flipbookFpsMin = neon.fpsMin,
            flipbookFpsMax = neon.fpsMax,
            sizeScale = 1.6,
            speedMin = 8,
            speedMax = 22,
            minTier = "Medium",
        },
        {
            at = t.peak,
            type = "Emit",
            count = 36,
            texture = spark.id,
            flipbookLayout = spark.layout,
            flipbookMode = spark.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = spark.fpsMin,
            flipbookFpsMax = spark.fpsMax,
            sizeScale = 0.85,
            speedMin = 14,
            speedMax = 32,
            minTier = "High",
        },
        { at = t.peak, type = "Shockwave", endSize = 16, duration = 0.45 },
        { at = t.body, type = "Beam", length = 14, minTier = "Medium" },
        { at = t.peak, type = "Light", range = 30, brightness = 5.2, duration = 0.42 },
        {
            at = t.peak,
            type = "ScreenFlash",
            brightness = 0.28,
            duration = 0.16,
            blurSize = 10,
            minTier = "Medium",
        },
        { at = t.peak + 0.02, type = "CameraShake", shakeProfile = "Heavy", minTier = "Low" },
        {
            at = t.recovery,
            type = "Emit",
            count = 18,
            sizeScale = 0.7,
            speedMin = 2,
            speedMax = 6,
            minTier = "High",
        },
    },
}

return CritImpact
