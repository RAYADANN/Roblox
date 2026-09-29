--!strict
-- Общие типы VFX-движка. Pure: без Roblox Instance API (CI / Lune).

export type QualityTier = "Low" | "Medium" | "High" | "Ultra"

export type FxPriority = "Low" | "Medium" | "High" | "Critical"

--- Burst = one-shot; Loop = до stop(); Attached = на Instance; Projectile = A→B; Screen = только постпроцесс; Chain = multi-point
export type EffectKind = "Burst" | "Loop" | "Attached" | "Projectile" | "Screen" | "Chain"

export type DeviceHints = {
    touchEnabled: boolean,
    savedQualityLevel: number,
    averageFps: number?,
    reduceMotion: boolean?,
}

export type QualityBudget = {
    tier: QualityTier,
    particleScale: number,
    maxEmitCount: number,
    maxConcurrent: number,
    enableLights: boolean,
    enableBeams: boolean,
    enableScreenFX: boolean,
    enableCameraShake: boolean,
    enableShockwave: boolean,
    enableTrails: boolean,
    enableLoops: boolean,
    maxDistance: number,
    lightBrightnessScale: number,
    layerMinPriority: FxPriority,
}

export type PriorityRank = { [FxPriority]: number }

local Types = {}

local PRIORITY_RANK: PriorityRank = {
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4,
}
Types.PRIORITY_RANK = PRIORITY_RANK

local TIER_RANK: { [QualityTier]: number } = {
    Low = 1,
    Medium = 2,
    High = 3,
    Ultra = 4,
}
Types.TIER_RANK = TIER_RANK

return Types
