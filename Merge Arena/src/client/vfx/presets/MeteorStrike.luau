--!strict
-- AAA showcase: MeteorStrike
-- Story: sky streak → ground punch → dual rings → ember rain → ash recovery.
-- Critical priority so soft-cap не глотает «ульту».

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local neon = TextureCatalog.NeonBurst
local spark = TextureCatalog.SparkBurst
local smoke = TextureCatalog.SmokePuff
local ember = TextureCatalog.EmberTrail

local MeteorStrike: EffectDef = {
    id = "MeteorStrike",
    kind = "Burst",
    priority = "Critical",
    lifetime = 2.4,
    layers = {
        -- === ANTICIPATION (sky warning) ===
        { at = 0, type = "Sound", soundId = "vfx_charge", pitch = 0.75 },
        { at = 0, type = "Haptic", hapticProfile = "Light", hapticStrength = 0.35 },
        { at = 0, type = "CameraRumble", rumble = 0.04, roughness = 14, minTier = "Medium" },
        {
            at = 0,
            type = "Emit",
            count = 8,
            texture = spark.id,
            flipbookLayout = spark.layout,
            flipbookMode = spark.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = 16,
            flipbookFpsMax = 22,
            sizeScale = 0.4,
            speedMin = 1,
            speedMax = 3,
            lifetimeMin = 0.35,
            lifetimeMax = 0.55,
        },
        {
            at = 0.05,
            type = "Beam",
            length = 22,
            width0 = 1.4,
            width1 = 0.15,
            duration = 0.35,
            minTier = "Medium",
        },
        {
            at = 0.05,
            type = "Light",
            range = 18,
            brightness = 2.2,
            duration = 0.4,
            minTier = "Medium",
        },

        -- === PEAK IMPACT ===
        { at = 0.32, type = "Sound", soundId = "vfx_slam", pitch = 0.9 },
        { at = 0.32, type = "Sound", soundId = "vfx_crit", pitch = 0.85 },
        { at = 0.32, type = "Haptic", hapticProfile = "Heavy", hapticStrength = 1 },
        -- Core nova
        {
            at = 0.32,
            type = "Emit",
            count = 48,
            texture = neon.id,
            flipbookLayout = neon.layout,
            flipbookMode = neon.mode,
            flipbookFpsMin = neon.fpsMin,
            flipbookFpsMax = neon.fpsMax,
            sizeScale = 1.7,
            speedMin = 8,
            speedMax = 24,
            minTier = "Medium",
        },
        -- Hot sparks
        {
            at = 0.33,
            type = "Emit",
            count = 40,
            texture = spark.id,
            flipbookLayout = spark.layout,
            flipbookMode = spark.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = spark.fpsMin,
            flipbookFpsMax = spark.fpsMax,
            sizeScale = 0.9,
            speedMin = 16,
            speedMax = 38,
            lifetimeMin = 0.3,
            lifetimeMax = 0.7,
            minTier = "High",
        },
        -- Dust / debris (cheap, always)
        { at = 0.32, type = "Emit", count = 22, sizeScale = 0.55, speedMin = 10, speedMax = 28 },
        -- Dual rings: fast then wide
        { at = 0.32, type = "Shockwave", endSize = 10, duration = 0.28 },
        { at = 0.38, type = "Shockwave", endSize = 22, duration = 0.55, minTier = "Medium" },
        { at = 0.34, type = "Beam", length = 16, width0 = 2.2, minTier = "High" },
        { at = 0.32, type = "Light", range = 36, brightness = 6.5, duration = 0.5 },
        {
            at = 0.32,
            type = "ScreenFlash",
            brightness = 0.32,
            duration = 0.18,
            blurSize = 12,
            minTier = "Medium",
        },
        { at = 0.33, type = "CameraShake", shakeProfile = "Heavy", minTier = "Low" },

        -- === EMBER RAIN ===
        {
            at = 0.48,
            type = "Emit",
            count = 28,
            texture = ember.id,
            flipbookLayout = ember.layout,
            flipbookMode = ember.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = ember.fpsMin,
            flipbookFpsMax = ember.fpsMax,
            sizeScale = 0.65,
            speedMin = 4,
            speedMax = 14,
            lifetimeMin = 0.5,
            lifetimeMax = 1.0,
            minTier = "High",
        },
        {
            at = 0.5,
            type = "Light",
            range = 20,
            brightness = 2.4,
            duration = 0.55,
            minTier = "High",
        },

        -- === ASH RECOVERY ===
        {
            at = 0.85,
            type = "Emit",
            count = 20,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = 8,
            flipbookFpsMax = 12,
            sizeScale = 1.5,
            speedMin = 0.4,
            speedMax = 2.2,
            lifetimeMin = 0.7,
            lifetimeMax = 1.2,
            minTier = "Medium",
        },
        {
            at = 0.9,
            type = "Light",
            range = 10,
            brightness = 0.9,
            duration = 0.7,
            minTier = "High",
        },
        -- stop rumble by setting 0 via a tiny delayed haptic-only beat (rumble cleared on effect stop)
    },
}

return MeteorStrike
