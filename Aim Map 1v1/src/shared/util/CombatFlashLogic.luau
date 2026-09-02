--!strict
-- Full-bleed combat screen wash: red on damage, blue on kill.
--# selene: allow(incorrect_standard_library_use)

local Constants = if script
    then require(script.Parent.Parent.data.Constants)
    else require("@shared/data/Constants")

export type Kind = "damage" | "kill"

local CombatFlashLogic = {}

function CombatFlashLogic.peakOpacity(kind: Kind, reduceMotion: boolean): number
    local base = if kind == "damage"
        then Constants.COMBAT_FLASH_DAMAGE_OPACITY
        else Constants.COMBAT_FLASH_KILL_OPACITY
    if reduceMotion then
        return base * 0.45
    end
    return base
end

function CombatFlashLogic.holdSec(reduceMotion: boolean): number
    if reduceMotion then
        return Constants.COMBAT_FLASH_HOLD_SEC * 0.5
    end
    return Constants.COMBAT_FLASH_HOLD_SEC
end

--- BackgroundTransparency from 0..1 opacity (1 = invisible).
function CombatFlashLogic.backgroundTransparency(opacity: number): number
    return 1 - math.clamp(opacity, 0, 1)
end

return CombatFlashLogic
