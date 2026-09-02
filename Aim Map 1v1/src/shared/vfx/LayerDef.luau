--!strict
-- Декларативные слои эффекта. Данные, не код. LayerRunner их исполняет.

local Types = require(script.Parent.Types)

export type QualityTier = Types.QualityTier
export type EffectKind = Types.EffectKind
export type FxPriority = Types.FxPriority

--- type дискриминирует payload. Лишние поля игнорируются runner'ом.
export type LayerStep = {
    at: number,
    minTier: QualityTier?,
    type: string,
    -- Emit / LoopEmit
    count: number?,
    rate: number?,
    texture: string?,
    flipbookLayout: string?,
    flipbookMode: string?,
    flipbookStartRandom: boolean?,
    flipbookFpsMin: number?,
    flipbookFpsMax: number?,
    sizeScale: number?,
    speedMin: number?,
    speedMax: number?,
    lifetimeMin: number?,
    lifetimeMax: number?,
    --- Emit style: fire | smoke | plasma | debris | ember | spark | soft | skyCombat | skySparks | skyPunch
    emitStyle: string?,
    lightEmission: number?,
    lightInfluence: number?,
    brightness: number?,
    sizeStart: number?,
    sizeMid: number?,
    sizeEnd: number?,
    drag: number?,
    spread: number?,
    emitDuration: number?,
    -- Light
    range: number?,
    brightness: number?,
    duration: number?,
    -- Shockwave
    endSize: number?,
    startSize: number?,
    -- Beam / Trail / Projectile
    length: number?,
    width0: number?,
    width1: number?,
    -- Camera
    amplitude: number?,
    roughness: number?,
    rumble: number?,
    shakeProfile: string?, -- Light | Medium | Heavy
    -- Screen
    -- brightness/duration reused
    blurSize: number?,
    speed: number?,
    -- Highlight
    fillTransparency: number?,
    outlineTransparency: number?,
    -- Sound / Haptic
    soundId: string?,
    pitch: number?,
    hapticProfile: string?, -- Light | Medium | Heavy
    hapticStrength: number?,
}

export type EffectDef = {
    id: string,
    kind: EffectKind,
    priority: FxPriority,
    --- Burst/Projectile/Screen: авто-stop. Loop/Attached: nil = до stop().
    lifetime: number?,
    --- Перекрывает budget.maxDistance если задано.
    maxDistance: number?,
    layers: { LayerStep },
}

local LayerDef = {}

return LayerDef
