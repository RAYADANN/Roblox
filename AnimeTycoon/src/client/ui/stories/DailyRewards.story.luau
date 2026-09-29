--!strict
-- Hoarcekat: DailyRewards. Path: ReplicatedStorage.UI.stories.DailyRewards
-- sync: center grid columns v2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DailyRewardsPanel = require(script.Parent.Parent.dailyRewards.DailyRewardsPanel)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(DailyRewardsPanel, {
        onClose = function()
            print("[DailyRewards] close")
        end,
        onClaim = function(id: string)
            print(`[DailyRewards] claim {id}`)
        end,
    })
end

return mount.screen(React.createElement(Story))
