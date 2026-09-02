--!strict
-- Pure fit math for DesignRoot (no Roblox services).

export type Size2 = { X: number, Y: number }

export type FitConfig = {
    reference: Size2,
    minScale: number,
    maxScale: number,
    fit: boolean,
    mobileBoost: number,
    mobileBelow: number,
}

local UiAdaptLogic = {}

function UiAdaptLogic.fitScale(usable: Size2, config: FitConfig): number
    if usable.X <= 1 or usable.Y <= 1 then
        return 1
    end

    local ref = config.reference
    local sx = usable.X / ref.X
    local sy = usable.Y / ref.Y
    local fitScale = math.min(sx, sy)
    local shortest = math.min(usable.X, usable.Y)
    local isPhone = shortest < config.mobileBelow

    if config.fit then
        return math.clamp(fitScale, math.min(config.minScale, fitScale), config.maxScale)
    end

    local raw = sx
    if isPhone and config.mobileBoost ~= 1 then
        raw *= config.mobileBoost
    end
    return math.clamp(raw, config.minScale, config.maxScale)
end

function UiAdaptLogic.canvasFits(usable: Size2, reference: Size2, scale: number): boolean
    local w = reference.X * scale
    local h = reference.Y * scale
    return w <= usable.X + 0.5 and h <= usable.Y + 0.5
end

return UiAdaptLogic
