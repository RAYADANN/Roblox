--!strict
-- Pure footstep gating (stride + ground/speed). Distance falloff → CombatAudioLogic.
--# selene: allow(incorrect_standard_library_use)

local FootstepLogic = {}

function FootstepLogic.shouldAccumulate(speed: number, minSpeed: number, onGround: boolean): boolean
    if not onGround then
        return false
    end
    if speed ~= speed or speed < minSpeed then
        return false
    end
    return true
end

--- Consume whole strides from distance accumulator. Returns (steps, remainder).
function FootstepLogic.consumeStrides(distanceAccum: number, stride: number): (number, number)
    if stride <= 0 or distanceAccum ~= distanceAccum or distanceAccum < 0 then
        return 0, 0
    end
    local steps = math.floor(distanceAccum / stride)
    local rem = distanceAccum - steps * stride
    return steps, rem
end

return FootstepLogic
