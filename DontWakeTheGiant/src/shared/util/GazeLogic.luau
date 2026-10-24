--!strict
-- Видит ли глаз игрока (GDD 4.2), без рейкаста укрытий: его делает сервер.

export type GazeCfg = {
    GAZE_HALF_ANGLE: number,
    GAZE_RANGE: number,
    GAZE_HEAVY_WEIGHT: number,
    MOVING_MIN_SPEED: number,
    GAZE_SWEEP_HALF_DEG: number,
    GAZE_TURN_DEG_PER_SEC: number,
}

export type Target = {
    dx: number, -- игрок минус глаз, по X
    dz: number,
    horizontalSpeed: number,
    sneaking: boolean,
    carryWeight: number,
}

local GazeLogic = {}

-- Стоящие и крадущиеся с лёгким грузом невидимы.
function GazeLogic.isConspicuous(t: Target, cfg: GazeCfg): boolean
    if t.horizontalSpeed <= cfg.MOVING_MIN_SPEED then
        return false
    end
    return not t.sneaking or t.carryWeight >= cfg.GAZE_HEAVY_WEIGHT
end

function GazeLogic.inCone(gazeYawDeg: number, t: Target, cfg: GazeCfg): boolean
    local dist = math.sqrt(t.dx * t.dx + t.dz * t.dz)
    if dist > cfg.GAZE_RANGE then
        return false
    end
    if dist < 1e-3 then
        return true
    end
    local yaw = math.rad(gazeYawDeg)
    local dot = (t.dx * math.cos(yaw) + t.dz * math.sin(yaw)) / dist
    return dot >= math.cos(math.rad(cfg.GAZE_HALF_ANGLE))
end

-- Угол взгляда в момент t: пинг-понг по дуге ±GAZE_SWEEP_HALF_DEG.
function GazeLogic.yawAt(t: number, cfg: GazeCfg): number
    local span = cfg.GAZE_SWEEP_HALF_DEG * 2
    local travel = (t * cfg.GAZE_TURN_DEG_PER_SEC) % (span * 2)
    local offset = if travel <= span then travel else span * 2 - travel
    return -cfg.GAZE_SWEEP_HALF_DEG + offset
end

return GazeLogic
