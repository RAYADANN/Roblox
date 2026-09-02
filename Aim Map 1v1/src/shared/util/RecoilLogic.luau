--!strict
-- USP camera punch: kick + exponential recover (pure). Degrees in / radians out for kicks.

local RecoilLogic = {}

export type KickConfig = {
    pitchDeg: number,
    yawDeg: number,
    maxPitchDeg: number,
    maxYawDeg: number,
    --- 0–1: how much of the pitch kick stays in true aim (CS-lite climb).
    aimKeep: number,
    --- Scale when reduce-motion is on.
    reduceScale: number,
}

local DEFAULT: KickConfig = {
    pitchDeg = 1.35,
    yawDeg = 0.45,
    maxPitchDeg = 4.2,
    maxYawDeg = 1.6,
    aimKeep = 0.22,
    reduceScale = 0.28,
}

function RecoilLogic.defaultConfig(): KickConfig
    return {
        pitchDeg = DEFAULT.pitchDeg,
        yawDeg = DEFAULT.yawDeg,
        maxPitchDeg = DEFAULT.maxPitchDeg,
        maxYawDeg = DEFAULT.maxYawDeg,
        aimKeep = DEFAULT.aimKeep,
        reduceScale = DEFAULT.reduceScale,
    }
end

--- yawUnit in [0, 1] → symmetric random horizontal kick.
function RecoilLogic.kick(
    yawUnit: number,
    reduceMotion: boolean,
    config: KickConfig?
): (number, number, number)
    local cfg = config or DEFAULT
    local scale = if reduceMotion then cfg.reduceScale else 1
    local pitch = math.rad(cfg.pitchDeg) * scale
    local yawSpan = math.rad(cfg.yawDeg) * scale
    local u = math.clamp(yawUnit, 0, 1)
    local yaw = (u * 2 - 1) * yawSpan
    local keep = math.clamp(cfg.aimKeep, 0, 1) * pitch
    return pitch, yaw, keep
end

function RecoilLogic.clampStack(
    pitchRad: number,
    yawRad: number,
    config: KickConfig?
): (number, number)
    local cfg = config or DEFAULT
    local maxP = math.rad(cfg.maxPitchDeg)
    local maxY = math.rad(cfg.maxYawDeg)
    return math.clamp(pitchRad, -maxP, maxP), math.clamp(yawRad, -maxY, maxY)
end

--- Exponential decay toward 0. Higher rate = snappier recover.
function RecoilLogic.decay(
    pitchRad: number,
    yawRad: number,
    dt: number,
    recoverRate: number
): (number, number)
    if dt <= 0 or recoverRate <= 0 then
        return pitchRad, yawRad
    end
    local k = math.exp(-recoverRate * dt)
    local p = pitchRad * k
    local y = yawRad * k
    if math.abs(p) < 1e-5 then
        p = 0
    end
    if math.abs(y) < 1e-5 then
        y = 0
    end
    return p, y
end

return RecoilLogic
