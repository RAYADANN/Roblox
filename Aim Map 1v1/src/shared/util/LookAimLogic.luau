--!strict
-- Look pitch → spine overlay (pro FPS: arms/gun follow aim up/down).
--# selene: allow(incorrect_standard_library_use)

local LookAimLogic = {}

function LookAimLogic.spinePitch(lookPitch: number, scale: number): number
    if lookPitch ~= lookPitch or scale ~= scale then
        return 0
    end
    local s = math.clamp(scale, 0, 1)
    return lookPitch * s
end

return LookAimLogic
