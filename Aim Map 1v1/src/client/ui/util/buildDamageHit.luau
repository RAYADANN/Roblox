--!strict
-- Build a DamageFeedbackLayer hit from TookDamage payload + local camera pose.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local DamageIndicatorLogic = require(ReplicatedStorage.shared.util.DamageIndicatorLogic)

export type DamageHit = {
    id: string,
    rotationDeg: number,
    strength: number,
    headshot: boolean,
}

local function buildDamageHit(
    id: string,
    damage: number,
    headshot: boolean,
    fromPos: Vector3
): DamageHit?
    local camera = workspace.CurrentCamera
    local character = Players.LocalPlayer.Character
    local pos: Vector3? = nil
    if character then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            pos = head.Position
        else
            local root = character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                pos = root.Position
            end
        end
    end
    if not pos and camera then
        pos = camera.CFrame.Position
    end
    if not camera or not pos then
        return nil
    end

    local look = camera.CFrame.LookVector
    local yaw = math.atan2(-look.X, -look.Z)
    local strength = DamageIndicatorLogic.vignetteStrength(damage, Constants.MATCH_PLAYER_HP)
    if headshot then
        strength = math.clamp(strength + 0.12, 0, 1)
    end

    return {
        id = id,
        rotationDeg = DamageIndicatorLogic.indicatorRotationDegrees(
            pos.X,
            pos.Z,
            yaw,
            fromPos.X,
            fromPos.Z
        ),
        strength = strength,
        headshot = headshot,
    }
end

return buildDamageHit
