--!strict
-- Local player Humanoid HP → React state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type LocalHealth = {
    health: number,
    maxHealth: number,
}

local function useLocalHealth(): LocalHealth
    local health, setHealth = React.useState(100)
    local maxHealth, setMaxHealth = React.useState(100)

    React.useEffect(function()
        local player = Players.LocalPlayer
        local conns: { RBXScriptConnection } = {}

        local function bind(character: Model)
            for _, c in conns do
                c:Disconnect()
            end
            table.clear(conns)

            local humanoid = character:WaitForChild("Humanoid", 5)
            if not humanoid or not humanoid:IsA("Humanoid") then
                return
            end

            local function sync()
                setHealth(humanoid.Health)
                setMaxHealth(humanoid.MaxHealth)
            end
            sync()
            table.insert(conns, humanoid.HealthChanged:Connect(sync))
            table.insert(conns, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(sync))
        end

        if player.Character then
            bind(player.Character)
        end
        local added = player.CharacterAdded:Connect(bind)

        return function()
            added:Disconnect()
            for _, c in conns do
                c:Disconnect()
            end
        end
    end, {})

    return {
        health = health,
        maxHealth = maxHealth,
    }
end

return useLocalHealth
