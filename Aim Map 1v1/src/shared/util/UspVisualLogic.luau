--!strict
-- Names of the equipped USP visual model on a character / viewmodel.
-- Muzzle tip: Studio Part "Shoot" on USP-S Main (authored), then legacy names.
--# selene: allow(incorrect_standard_library_use)

local UspVisualLogic = {}

local GUN_NAMES: { [string]: boolean } = {
    USP = true,
    ["USP-S Main"] = true,
    ["UPS-S Main"] = true,
}

-- Prefer authored Shoot tip; older templates may use AimPart/Muzzle/Barrel/Handle.
local MUZZLE_PART_NAMES = { "Shoot", "AimPart", "Muzzle", "Barrel", "Handle" }

function UspVisualLogic.isGunModelName(name: string): boolean
    return GUN_NAMES[name] == true
end

function UspVisualLogic.muzzlePartNames(): { string }
    return MUZZLE_PART_NAMES
end

function UspVisualLogic.findGunModel(root: Instance): Model?
    for _, child in root:GetChildren() do
        if child:IsA("Model") and UspVisualLogic.isGunModelName(child.Name) then
            return child
        end
    end
    for _, desc in root:GetDescendants() do
        if desc:IsA("Model") and UspVisualLogic.isGunModelName(desc.Name) then
            return desc
        end
    end
    return nil
end

--- Authored muzzle is Part "Shoot" parented to Handle (Studio dummy), not a sibling guess.
function UspVisualLogic.hasAuthoredShoot(gun: Instance): boolean
    local handle = gun:FindFirstChild("Handle")
    if not handle then
        return false
    end
    local shoot = handle:FindFirstChild("Shoot")
    return shoot ~= nil and shoot:IsA("BasePart")
end

function UspVisualLogic.findMuzzlePart(root: Instance): BasePart?
    local gun = UspVisualLogic.findGunModel(root)
    local searchRoot: Instance = if gun then gun else root
    local handle = searchRoot:FindFirstChild("Handle")
    if handle then
        local authored = handle:FindFirstChild("Shoot")
        if authored and authored:IsA("BasePart") then
            return authored
        end
    end
    for _, name in MUZZLE_PART_NAMES do
        local found = searchRoot:FindFirstChild(name, true)
        if found and found:IsA("BasePart") then
            return found
        end
    end
    return nil
end

--- Weld every gun BasePart to Handle. Safe to call repeatedly (skips existing pairs).
--- Call while the gun is still in its authored rest pose so Shoot keeps the muzzle offset.
function UspVisualLogic.assembleGunToHandle(gun: Model): boolean
    local handle = gun:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        return false
    end

    local welded: { [BasePart]: boolean } = {}
    for _, child in handle:GetChildren() do
        if child:IsA("WeldConstraint") then
            if child.Part0 and child.Part0:IsA("BasePart") then
                welded[child.Part0] = true
            end
            if child.Part1 and child.Part1:IsA("BasePart") then
                welded[child.Part1] = true
            end
        end
    end
    welded[handle] = true

    for _, desc in gun:GetDescendants() do
        if desc:IsA("BasePart") and not welded[desc] then
            local weld = Instance.new("WeldConstraint")
            weld.Name = "USPAssembly"
            weld.Part0 = handle
            weld.Part1 = desc
            weld.Parent = handle
            welded[desc] = true
        end
    end

    gun.PrimaryPart = handle
    return true
end

--- Muzzle parts must render on the viewmodel and stay welded / non-colliding.
function UspVisualLogic.prepareMuzzleParts(gun: Model)
    for _, name in MUZZLE_PART_NAMES do
        local part = gun:FindFirstChild(name, true)
        if part and part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Massless = true
            if part.Name == "Shoot" then
                -- Marker only — keep invisible, but don't let FP hide-logic swallow Position.
                part.Transparency = 1
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

--- World position for tracer / fire FX. Shoot is the tip — use Position as-is.
--- Handle fallback pushes slightly along LookVector so the line clears the mesh.
function UspVisualLogic.muzzleWorldPosition(root: Instance): Vector3?
    local part = UspVisualLogic.findMuzzlePart(root)
    if not part then
        return nil
    end
    if part.Name == "Shoot" then
        return part.Position
    end
    return part.Position + part.CFrame.LookVector * 0.35
end

return UspVisualLogic
