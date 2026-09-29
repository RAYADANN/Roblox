--!strict
-- Hoarcekat: Hud + окна + blur/zoom. Path: ReplicatedStorage.UI.stories.Hud
-- sync: HUD labels uniformFitRef REWARDS + adaptive v5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudShell = require(script.Parent.Parent.HudShell)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(HudShell, {
        moneyText = "$100M",
        onRebirth = function()
            print("[Hud] rebirth (no window yet)")
        end,
    })
end

return mount.screen(React.createElement(Story))
