--!strict
-- Hoarcekat: Rewards. Path: ReplicatedStorage.UI.stories.Rewards
-- sync: 2x cards/cases + scroll grid v12

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MockData = require(script.Parent.Parent.rewards.MockData)
local RewardsPanel = require(script.Parent.Parent.rewards.RewardsPanel)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(RewardsPanel, {
        -- Demo: first two claimed → #3 Golden Case claimable (big 3D box).
        items = MockData.items({ claimedCount = 2 }),
        onClose = function()
            print("[Rewards] close")
        end,
        onSkipAll = function()
            print("[Rewards] skip all")
        end,
        onClaim = function(id: string, from: Vector2)
            print(`[Rewards] claim {id} from={from}`)
        end,
    })
end

return mount.screen(React.createElement(Story))
