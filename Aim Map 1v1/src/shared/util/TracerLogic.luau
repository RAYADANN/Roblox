--!strict
-- First-person muzzle offset math (camera space → world). Pure for CI.
--# selene: allow(incorrect_standard_library_use)

local TracerLogic = {}

--- Camera basis + local offset (right, up, forward) → world muzzle.
--- forward is along look (positive = in front of camera).
function TracerLogic.fpMuzzleWorld(
    camX: number,
    camY: number,
    camZ: number,
    rightX: number,
    rightY: number,
    rightZ: number,
    upX: number,
    upY: number,
    upZ: number,
    lookX: number,
    lookY: number,
    lookZ: number,
    offsetRight: number,
    offsetUp: number,
    offsetForward: number
): (number, number, number)
    return camX + rightX * offsetRight + upX * offsetUp + lookX * offsetForward,
        camY + rightY * offsetRight + upY * offsetUp + lookY * offsetForward,
        camZ + rightZ * offsetRight + upZ * offsetUp + lookZ * offsetForward
end

--- Delta from muzzle to the camera aim point (hitscan / tracer direction).
function TracerLogic.muzzleAimDelta(
    muzzleX: number,
    muzzleY: number,
    muzzleZ: number,
    aimX: number,
    aimY: number,
    aimZ: number
): (number, number, number)
    return aimX - muzzleX, aimY - muzzleY, aimZ - muzzleZ
end

--- Tracer end is the impact so the streak meets the crosshair (not a parallel miss).
function TracerLogic.fpTraceEnd(
    muzzleX: number,
    muzzleY: number,
    muzzleZ: number,
    hitX: number,
    hitY: number,
    hitZ: number
): (number, number, number)
    local dx = hitX - muzzleX
    local dy = hitY - muzzleY
    local dz = hitZ - muzzleZ
    if (dx * dx + dy * dy + dz * dz) < 1e-8 then
        return muzzleX, muzzleY, muzzleZ
    end
    return hitX, hitY, hitZ
end

return TracerLogic
