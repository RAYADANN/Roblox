--!strict
-- Pure knock vector for CS-style death ragdoll.
--# selene: allow(incorrect_standard_library_use)

local RagdollLogic = {}

--- Unit shot direction → linear velocity (studs/s) with slight upward lift.
function RagdollLogic.knockVelocity(
    dirX: number,
    dirY: number,
    dirZ: number,
    speed: number,
    upBias: number
): (number, number, number)
    local mag = math.sqrt(dirX * dirX + dirY * dirY + dirZ * dirZ)
    if mag < 1e-4 or speed <= 0 then
        return 0, upBias, 0
    end
    local nx = dirX / mag
    local ny = dirY / mag
    local nz = dirZ / mag
    return nx * speed, ny * speed + upBias, nz * speed
end

return RagdollLogic
