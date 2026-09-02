--!strict
-- Soft heal pulse — readable, not combat-loud.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local neon = TextureCatalog.NeonBurst

local HealPulse: EffectDef = {
    id = "HealPulse",
    kind = "Burst",
    priority = "Medium",
    lifetime = 1.3,
    layers = {
        { at = 0, type = "Sound", soundId = "vfx_heal", pitch = 1.15 },
        { at = 0.02, type = "Haptic", hapticProfile = "Light" },
        {
            at = 0,
            type = "Emit",
            count = 18,
            texture = neon.id,
            flipbookLayout = neon.layout,
            flipbookMode = neon.mode,
            flipbookFpsMin = 12,
            flipbookFpsMax = 16,
            sizeScale = 0.9,
            speedMin = 1.5,
            speedMax = 5,
        },
        { at = 0.04, type = "Shockwave", endSize = 9, duration = 0.4, minTier = "Medium" },
        { at = 0.02, type = "Light", range = 14, brightness = 2.2, duration = 0.45 },
        {
            at = 0.05,
            type = "ScreenFlash",
            brightness = 0.08,
            duration = 0.14,
            blurSize = 3,
            minTier = "High",
        },
        { at = 0.04, type = "CameraShake", shakeProfile = "Light", minTier = "High" },
        {
            at = 0.3,
            type = "Emit",
            count = 10,
            texture = neon.id,
            flipbookLayout = neon.layout,
            flipbookMode = neon.mode,
            sizeScale = 0.7,
            speedMin = 0.5,
            speedMax = 2,
            minTier = "High",
        },
    },
}

return HealPulse
