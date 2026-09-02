--!strict
-- World-space USP muzzle for remote tracers (others see shot leave the gun, not the skull).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UspVisualLogic = require(ReplicatedStorage.shared.util.UspVisualLogic)

local WorldMuzzle = {}

function WorldMuzzle.ofCharacter(character: Model): Vector3?
    local muzzle = UspVisualLogic.muzzleWorldPosition(character)
    if muzzle then
        return muzzle
    end

    local hand = character:FindFirstChild("RightHand")
    if hand and hand:IsA("BasePart") then
        return hand.Position + hand.CFrame.LookVector * 0.5
    end
    local lowerArm = character:FindFirstChild("RightLowerArm")
    if lowerArm and lowerArm:IsA("BasePart") then
        return lowerArm.Position + lowerArm.CFrame.LookVector * 0.5
    end

    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head.Position
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root.Position + Vector3.new(0, 1.4, 0)
    end

    return nil
end

return WorldMuzzle
