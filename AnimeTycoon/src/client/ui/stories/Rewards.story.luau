--!strict
-- Hoarcekat: Rewards. Path: ReplicatedStorage.UI.stories.Rewards
-- sync: claim stroke white v8

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local RewardsPanel = require(script.Parent.Parent.rewards.RewardsPanel)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(RewardsPanel, {
        onClose = function()
            print("[Rewards] close")
        end,
        onSkipAll = function()
            print("[Rewards] skip all")
        end,
        onClaim = function(id: string)
            print(`[Rewards] claim {id}`)
        end,
    })
end

return mount.screen(React.createElement(Story))
