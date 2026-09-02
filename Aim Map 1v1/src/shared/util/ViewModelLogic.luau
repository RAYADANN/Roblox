--!strict
-- FP viewmodel: which R15 parts stay on the camera rig, and camera-local offset.
-- Pure numbers only (Lune CI has no CFrame).
--# selene: allow(incorrect_standard_library_use)

local ViewModelLogic = {}

-- Legs / head are stripped so Idle/Shoot arms sit in front of the lens.
local STRIP_PARTS: { [string]: boolean } = {
    Head = true,
    LeftUpperLeg = true,
    LeftLowerLeg = true,
    LeftFoot = true,
    RightUpperLeg = true,
    RightLowerLeg = true,
    RightFoot = true,
}

-- Keep for Motor6D Part0; hide so the camera is not inside a chest mesh.
local HIDE_MESH: { [string]: boolean } = {
    UpperTorso = true,
    LowerTorso = true,
    HumanoidRootPart = true,
}

function ViewModelLogic.shouldStripPart(name: string): boolean
    return STRIP_PARTS[name] == true
end

function ViewModelLogic.shouldHideMesh(name: string): boolean
    return HIDE_MESH[name] == true
end

--- Head-center Y minus HRP Y. Fallback if the rig is missing a head.
function ViewModelLogic.eyeHeight(headY: number, rootY: number, fallback: number): number
    local height = headY - rootY
    if height ~= height or height < 0.5 or height > 5 then
        return fallback
    end
    return height
end

--- Camera-space translation: +right, +up, +forward (along look) → (x, y, z) with look = -Z.
function ViewModelLogic.localOffset(
    right: number,
    up: number,
    forward: number
): (number, number, number)
    return right, up, -forward
end

--- HRP in camera space so the rig's eyes sit on the lens, plus extra aim offset.
function ViewModelLogic.cameraLocalOffset(
    eyeHeight: number,
    right: number,
    up: number,
    forward: number
): (number, number, number)
    return right, -eyeHeight + up, -forward
end

--- World position of viewmodel root from camera basis + local offset.
function ViewModelLogic.rigPosition(
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

return ViewModelLogic
