--!strict
-- Apply Speed Boost WalkSpeed from upgrade levels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

local SpeedBoostVisual = {}

local _upgrades: { [string]: number } = {}

local function applyToCharacter(character: Model?)
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    humanoid.WalkSpeed = UpgradeLogic.walkSpeed(_upgrades)
end

function SpeedBoostVisual.apply(upgrades: { [string]: number }?)
    _upgrades = upgrades or {}
    local player = Players.LocalPlayer
    if player then
        applyToCharacter(player.Character)
    end
end

function SpeedBoostVisual.start()
    local player = Players.LocalPlayer
    if not player then
        return
    end
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            applyToCharacter(character)
        end)
    end)
    applyToCharacter(player.Character)
end

return SpeedBoostVisual
