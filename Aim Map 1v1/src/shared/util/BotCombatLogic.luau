--!strict
-- Pure duel-bot combat helpers (aim error, reaction, movement bands).
-- Uses plain Vec3 so Lune CI can run without Roblox Vector3.
--# selene: allow(incorrect_standard_library_use)

local Constants = if script
    then require(script.Parent.Parent.data.Constants)
    else require("@shared/data/Constants")

export type MoveBand = "advance" | "hold" | "retreat"
export type Rng = () -> number
export type Vec3 = { x: number, y: number, z: number }

local BotCombatLogic = {}

local function vec(x: number, y: number, z: number): Vec3
    return { x = x, y = y, z = z }
end

local function mag(v: Vec3): number
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

local function unit(v: Vec3): Vec3
    local m = mag(v)
    if m < 1e-6 then
        return vec(0, 0, 0)
    end
    return vec(v.x / m, v.y / m, v.z / m)
end

local function add(a: Vec3, b: Vec3): Vec3
    return vec(a.x + b.x, a.y + b.y, a.z + b.z)
end

local function scale(v: Vec3, s: number): Vec3
    return vec(v.x * s, v.y * s, v.z * s)
end

local function cross(a: Vec3, b: Vec3): Vec3
    return vec(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

local function dot(a: Vec3, b: Vec3): number
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function BotCombatLogic.vec(x: number, y: number, z: number): Vec3
    return vec(x, y, z)
end

function BotCombatLogic.dot(a: Vec3, b: Vec3): number
    return dot(a, b)
end

function BotCombatLogic.isBotUserId(userId: number): boolean
    return userId == Constants.BOT_USER_ID
end

function BotCombatLogic.moveBand(distance: number): MoveBand
    if distance < Constants.BOT_ENGAGE_MIN_STUDS then
        return "retreat"
    elseif distance > Constants.BOT_ENGAGE_MAX_STUDS then
        return "advance"
    end
    return "hold"
end

--- Alternating -1 / +1 for lateral strafe.
function BotCombatLogic.strafeSign(timeSec: number, periodSec: number?): number
    local period = if periodSec and periodSec > 0
        then periodSec
        else Constants.BOT_STRAFE_PERIOD_SEC
    local phase = math.floor(timeSec / period)
    return if phase % 2 == 0 then 1 else -1
end

--- Horizontal move intent (not necessarily unit).
function BotCombatLogic.moveDirection(
    botPos: Vec3,
    targetPos: Vec3,
    band: MoveBand,
    strafeSign: number
): Vec3
    local toTarget = vec(targetPos.x - botPos.x, 0, targetPos.z - botPos.z)
    if mag(toTarget) < 0.05 then
        return vec(strafeSign, 0, 0)
    end
    local forward = unit(toTarget)
    local right = vec(-forward.z, 0, forward.x)
    local lateral = scale(right, strafeSign)

    if band == "advance" then
        return add(scale(forward, 0.85), scale(lateral, 0.55))
    elseif band == "retreat" then
        return add(scale(forward, -0.75), scale(lateral, 0.65))
    end
    return add(scale(lateral, 0.95), scale(forward, 0.12))
end

function BotCombatLogic.rollReaction(rng: Rng): number
    local u = math.clamp(rng(), 0, 1)
    local lo = Constants.BOT_REACTION_MIN_SEC
    local hi = Constants.BOT_REACTION_MAX_SEC
    return lo + u * (hi - lo)
end

function BotCombatLogic.rollAimError(rng: Rng): number
    return rng() * Constants.BOT_AIM_ERROR_MAX_RAD
end

--- Offset aim direction by a small cone (seedable via rng).
function BotCombatLogic.aimWithError(from: Vec3, to: Vec3, errorRad: number, rng: Rng): Vec3
    local delta = vec(to.x - from.x, to.y - from.y, to.z - from.z)
    if mag(delta) < 1e-4 then
        return vec(0, 0, -1)
    end
    local dir = unit(delta)
    if errorRad <= 0 then
        return dir
    end

    local up = vec(0, 1, 0)
    local right = cross(dir, up)
    if mag(right) < 1e-4 then
        right = cross(dir, vec(1, 0, 0))
    end
    right = unit(right)
    local trueUp = unit(cross(right, dir))

    local yaw = (rng() * 2 - 1) * errorRad
    local pitch = (rng() * 2 - 1) * errorRad
    local skewed = add(dir, add(scale(right, math.tan(yaw)), scale(trueUp, math.tan(pitch))))
    if mag(skewed) < 1e-4 then
        return dir
    end
    return unit(skewed)
end

function BotCombatLogic.rememberTarget(
    hasLos: boolean,
    timeSinceSeen: number,
    memorySec: number?
): boolean
    local mem = if memorySec and memorySec > 0 then memorySec else Constants.BOT_TARGET_MEMORY_SEC
    if hasLos then
        return true
    end
    return timeSinceSeen <= mem
end

function BotCombatLogic.canFire(
    hasLos: boolean,
    timeSinceAcquired: number,
    reactionSec: number,
    timeSinceShot: number,
    cooldownSec: number
): boolean
    if not hasLos then
        return false
    end
    if timeSinceAcquired < reactionSec then
        return false
    end
    if timeSinceShot < cooldownSec then
        return false
    end
    return true
end

--- Extra pause after a shot so the bot does not tap at full USP rate.
function BotCombatLogic.rollFireCooldown(rng: Rng): number
    local u = math.clamp(rng(), 0, 1)
    return Constants.BOT_FIRE_COOLDOWN_SEC + u * Constants.BOT_FIRE_JITTER_SEC
end

return BotCombatLogic
