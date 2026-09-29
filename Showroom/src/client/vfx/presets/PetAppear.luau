--!strict
-- Content signature: pet appear / equip (collectible loop).
-- Soft candy pop — cute, readable, not combat-loud.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local neon = TextureCatalog.NeonBurst
local spark = TextureCatalog.SparkBurst

local PetAppear: EffectDef = {
    id = "PetAppear",
    kind = "Burst",
    priority = "Medium",
    lifetime = 1.4,
    layers = {
        { at = 0, type = "Sound", soundId = "vfx_heal", pitch = 1.4 },
        { at = 0.02, type = "Haptic", hapticProfile = "Light" },
        -- Soft bloom core
        {
            at = 0,
            type = "Emit",
            count = 14,
            texture = neon.id,
            flipbookLayout = neon.layout,
            flipbookMode = neon.mode,
            flipbookFpsMin = 14,
            flipbookFpsMax = 18,
            sizeScale = 0.85,
            speedMin = 1.5,
            speedMax = 5,
            lifetimeMin = 0.35,
            lifetimeMax = 0.65,
        },
        -- Star sparkles
        {
            at = 0.06,
            type = "Emit",
            count = 22,
            texture = spark.id,
            flipbookLayout = spark.layout,
            flipbookMode = spark.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = spark.fpsMin,
            flipbookFpsMax = spark.fpsMax,
            sizeScale = 0.45,
            speedMin = 3,
            speedMax = 11,
            minTier = "Medium",
        },
        { at = 0.04, type = "Shockwave", endSize = 6, duration = 0.35, minTier = "Medium" },
        { at = 0.02, type = "Light", range = 12, brightness = 2.6, duration = 0.4 },
        {
            at = 0.05,
            type = "ScreenFlash",
            brightness = 0.08,
            duration = 0.12,
            blurSize = 3,
            minTier = "High",
        },
        { at = 0.05, type = "CameraShake", shakeProfile = "Light", minTier = "High" },
        -- Residual glitter
        {
            at = 0.35,
            type = "Emit",
            count = 10,
            texture = spark.id,
            flipbookLayout = spark.layout,
            flipbookMode = spark.mode,
            flipbookStartRandom = true,
            sizeScale = 0.35,
            speedMin = 0.5,
            speedMax = 2.5,
            minTier = "High",
        },
        {
            at = 0,
            type = "Highlight",
            duration = 0.35,
            fillTransparency = 0.55,
            outlineTransparency = 0.2,
            minTier = "Medium",
        },
    },
}

return PetAppear
