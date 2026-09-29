--!strict
-- High-quality ambient smoke plume (flipbook Loop, multi-layer). Stop via handle:stop().

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)

export type EffectDef = LayerDef.EffectDef

local smoke = TextureCatalog.SmokeLoop

local AmbientSmoke: EffectDef = {
    id = "AmbientSmoke",
    kind = "Loop",
    priority = "Medium",
    lifetime = nil,
    layers = {
        -- Soft large billows (volume)
        {
            at = 0,
            type = "LoopEmit",
            rate = 7,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = smoke.fpsMin,
            flipbookFpsMax = smoke.fpsMax,
            emitStyle = "smoke",
            sizeStart = 2.2,
            sizeMid = 4.8,
            sizeEnd = 6.5,
            speedMin = 0.35,
            speedMax = 1.1,
            lifetimeMin = 2.4,
            lifetimeMax = 3.8,
            spread = 55,
            drag = 1.1,
            lightEmission = 0.02,
            accelerationY = 1.35,
        },
        -- Medium wisps (motion read)
        {
            at = 0,
            type = "LoopEmit",
            rate = 12,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = 10,
            flipbookFpsMax = 14,
            emitStyle = "smoke",
            sizeStart = 1.1,
            sizeMid = 2.6,
            sizeEnd = 3.4,
            speedMin = 0.6,
            speedMax = 1.8,
            lifetimeMin = 1.6,
            lifetimeMax = 2.6,
            spread = 70,
            drag = 0.85,
            lightEmission = 0.03,
            accelerationY = 1.8,
            minTier = "Medium",
        },
        -- Fine detail (edge breakup)
        {
            at = 0,
            type = "LoopEmit",
            rate = 9,
            texture = smoke.id,
            flipbookLayout = smoke.layout,
            flipbookMode = smoke.mode,
            flipbookStartRandom = true,
            flipbookFpsMin = 12,
            flipbookFpsMax = 16,
            emitStyle = "smoke",
            sizeStart = 0.55,
            sizeMid = 1.4,
            sizeEnd = 2.0,
            speedMin = 0.9,
            speedMax = 2.4,
            lifetimeMin = 1.1,
            lifetimeMax = 1.9,
            spread = 90,
            drag = 0.6,
            lightEmission = 0.04,
            accelerationY = 2.2,
            minTier = "High",
        },
    },
}

return AmbientSmoke
