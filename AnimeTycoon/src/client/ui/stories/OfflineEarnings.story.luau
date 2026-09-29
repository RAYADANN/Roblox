--!strict
-- Hoarcekat: Offline Earnings. Path: ReplicatedStorage.UI.stories.OfflineEarnings
-- sync: title bar ScaleType Fit v5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local OfflineEarningsPanel = require(script.Parent.Parent.offlineEarnings.OfflineEarningsPanel)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(OfflineEarningsPanel, {
        onCancel = function()
            print("[OfflineEarnings] cancel")
        end,
        onDouble = function()
            print("[OfflineEarnings] double")
        end,
    })
end

return mount.screen(React.createElement(Story))
