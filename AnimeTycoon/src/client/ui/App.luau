--!strict
-- Корневой UI: StarterGui HUD + окна (Shop / Index / Rewards).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Formatters = require(script.Parent.util.Formatters)
local HudContext = require(script.Parent.context.HudContext)
local HudShell = require(script.Parent.HudShell)
local SoundManager = require(script.Parent.Parent.core.SoundManager)

local function App(): React.Node
    local ctx = React.useContext(HudContext)
    local moneyText = `$${Formatters.shortNumber(ctx.hud.coins)}`

    return React.createElement(HudShell, {
        moneyText = moneyText,
        onRebirth = function()
            SoundManager.play("ui_click")
            -- Rebirth window ещё нет — см. docs/BACKLOG.md
        end,
    })
end

return App
