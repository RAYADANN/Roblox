--!strict
-- Hoarcekat: Hud + окна + blur/zoom. Path: ReplicatedStorage.UI.stories.Hud
-- sync: 2x HUD icons + Rewards attention v12

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudShell = require(script.Parent.Parent.HudShell)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(HudShell, {
        coins = 100_000_000,
        onRebirth = function()
            print("[Hud] rebirth (no window yet)")
        end,
    })
end

return mount.screen(React.createElement(Story))
