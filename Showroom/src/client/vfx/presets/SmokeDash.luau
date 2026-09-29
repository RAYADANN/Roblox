--!strict
-- Signature Smoke dash + whoosh/haptic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local StyleTokens = require(ReplicatedStorage.shared.vfx.StyleTokens)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local smoke = TextureCatalog.SmokePuff
local ember = TextureCatalog.EmberTrail
local t = StyleTokens.timing

local SmokeDash: EffectDef = {
    id = "SmokeDash",
    kind = "Burst",
    priority = "High",
    lifetime = 1.35,
    layers = {
        { at = 0, type = "Sound", soundId = "vfx_whoosh", pitch = 1.1 },
        { at = 0.02, type = "Haptic", hapticProfile = "Light" },
        {
            at = 0,
            type = "Emit",
            count = 14,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = smoke.fpsMin,
            flipbookFpsMax = smoke.fpsMax,
            sizeScale = 0.7,
            speedMin = 2,
            speedMax = 6,
            lifetimeMin = 0.25,
            lifetimeMax = 0.45,
        },
        {
            at = t.peak,
            type = "Emit",
            count = 36,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = smoke.fpsMin,
            flipbookFpsMax = smoke.fpsMax,
            sizeScale = 1.4,
            speedMin = 4,
            speedMax = 12,
            minTier = "Medium",
        },
        { at = 0.02, type = "Trail", duration = 0.55, width0 = 1.9, minTier = "Medium" },
        {
            at = t.peak,
            type = "Emit",
            count = 18,
            texture = ember.id,
            flipbookLayout = ember.layout,
            flipbookMode = ember.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = ember.fpsMin,
            flipbookFpsMax = ember.fpsMax,
            sizeScale = 0.55,
            speedMin = 6,
            speedMax = 16,
            lifetimeMin = 0.3,
            lifetimeMax = 0.65,
            minTier = "High",
        },
        { at = t.peak, type = "Emit", count = 10, sizeScale = 0.35, speedMin = 8, speedMax = 18 },
        { at = t.peak, type = "Beam", length = 9, minTier = "High" },
        {
            at = 0.02,
            type = "Light",
            range = 14,
            brightness = 1.8,
            duration = 0.28,
            minTier = "Medium",
        },
        { at = t.peak, type = "CameraShake", shakeProfile = "Light", minTier = "High" },
        {
            at = t.recovery,
            type = "Emit",
            count = 10,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookStartRandom = true,
            sizeScale = 1.1,
            speedMin = 0.5,
            speedMax = 2.5,
            minTier = "High",
        },
    },
}

return SmokeDash
