--!strict
-- Single preset: fit 1920×1080 canvas into safe host. No per-device layout.

local REFERENCE = Vector2.new(1920, 1080)

export type ScaleConfig = {
    reference: Vector2?,
    minScale: number?,
    maxScale: number?,
    fit: boolean?,
    mobileBoost: number?,
    mobileBelow: number?,
}

local DEFAULT: ScaleConfig = {
    reference = REFERENCE,
    minScale = 0.3,
    maxScale = 1.2,
    fit = true,
    mobileBoost = 1,
    mobileBelow = 900,
}

return {
    REFERENCE = REFERENCE,
    DEFAULT = DEFAULT,
}
