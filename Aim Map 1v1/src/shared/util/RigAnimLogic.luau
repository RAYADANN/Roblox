--!strict
-- Pure gates for R15 locomotion / nearest-shooter matching.
--# selene: allow(incorrect_standard_library_use)

local RigAnimLogic = {}

function RigAnimLogic.shouldWalk(speed: number, minSpeed: number): boolean
    if speed ~= speed or minSpeed ~= minSpeed then
        return false
    end
    return speed >= minSpeed
end

function RigAnimLogic.isNear(distance: number, maxDistance: number): boolean
    if distance ~= distance or maxDistance ~= maxDistance then
        return false
    end
    return distance >= 0 and distance <= maxDistance
end

return RigAnimLogic
