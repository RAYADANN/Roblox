--!strict
-- Distance falloff for remote gunfire (CS-style: loud up close, quiet far).
--# selene: allow(incorrect_standard_library_use)

local CombatAudioLogic = {}

--- Volume scale in [0, 1]. Full until fullDist, then ease to 0 at maxDist.
function CombatAudioLogic.remoteFireVolume(
    distance: number,
    fullDist: number,
    maxDist: number
): number
    if distance ~= distance or distance < 0 then
        return 0
    end
    if maxDist <= fullDist then
        return if distance <= fullDist then 1 else 0
    end
    if distance <= fullDist then
        return 1
    end
    if distance >= maxDist then
        return 0
    end
    local t = (distance - fullDist) / (maxDist - fullDist)
    -- Smoothstep-ish: stays audible mid-range, drops harder at the end.
    local fade = 1 - t
    return fade * fade
end

return CombatAudioLogic
