--!strict
-- Pure USP hit rules (damage, range, origin sanity helpers).
--# selene: allow(incorrect_standard_library_use)

local Constants = if script
    then require(script.Parent.Parent.data.Constants)
    else require("@shared/data/Constants")

export type HitZone = "head" | "body"

local WeaponLogic = {}

function WeaponLogic.damageForZone(zone: HitZone): number
    if zone == "head" then
        return Constants.USP_DAMAGE_HEAD
    end
    return Constants.USP_DAMAGE_BODY
end

function WeaponLogic.isInRange(distance: number): boolean
    return distance >= 0 and distance <= Constants.USP_MAX_RANGE_STUDS
end

function WeaponLogic.isOriginSane(originDistance: number): boolean
    return originDistance >= 0 and originDistance <= Constants.USP_ORIGIN_SLACK_STUDS
end

function WeaponLogic.directionMagnitudeOk(magnitude: number): boolean
    return magnitude >= 0.01
end

function WeaponLogic.zoneFromPart(partName: string): HitZone
    local lower = string.lower(partName)
    if string.find(lower, "head", 1, true) then
        return "head"
    end
    return "body"
end

function WeaponLogic.applyDamage(currentHp: number, damage: number): number
    return math.max(0, currentHp - damage)
end

function WeaponLogic.isLethal(hpAfter: number): boolean
    return hpAfter <= 0
end

return WeaponLogic
