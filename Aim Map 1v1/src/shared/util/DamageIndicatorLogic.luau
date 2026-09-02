--!strict
-- Pure helpers for Valorant-style take-damage UI (bearing + vignette strength).
--# selene: allow(incorrect_standard_library_use)

local DamageIndicatorLogic = {}

function DamageIndicatorLogic.normalizeAngle(radians: number): number
    local a = radians
    while a > math.pi do
        a -= 2 * math.pi
    end
    while a < -math.pi do
        a += 2 * math.pi
    end
    return a
end

--- Look yaw convention matches LookController: atan2(-look.X, -look.Z).
--- Returns relative bearing radians: 0 = ahead, negative = right, positive = left
--- (world yaw space). Prefer indicatorRotationDegrees for UI.
function DamageIndicatorLogic.relativeBearing(
    listenerX: number,
    listenerZ: number,
    lookYaw: number,
    sourceX: number,
    sourceZ: number
): number
    local dx = sourceX - listenerX
    local dz = sourceZ - listenerZ
    if dx * dx + dz * dz < 1e-6 then
        return 0
    end
    local toYaw = math.atan2(-dx, -dz)
    return DamageIndicatorLogic.normalizeAngle(toYaw - lookYaw)
end

--- GuiObject.Rotation degrees: 0 = ahead (top), positive = clockwise (right).
function DamageIndicatorLogic.indicatorRotationDegrees(
    listenerX: number,
    listenerZ: number,
    lookYaw: number,
    sourceX: number,
    sourceZ: number
): number
    local rel =
        DamageIndicatorLogic.relativeBearing(listenerX, listenerZ, lookYaw, sourceX, sourceZ)
    return -math.deg(rel)
end

--- 0..1 screen vignette strength from damage fraction of max HP.
function DamageIndicatorLogic.vignetteStrength(damage: number, maxHp: number): number
    if maxHp <= 0 or damage <= 0 then
        return 0
    end
    local t = math.clamp(damage / maxHp, 0, 1)
    return 0.45 + t * 0.5
end

return DamageIndicatorLogic
