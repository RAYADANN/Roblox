--!strict
-- Корневой UI: StarterGui HUD + окна (Shop / Index / Rewards).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.context.HudContext)
local HudShell = require(script.Parent.HudShell)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local Zap = require(script.Parent.Parent.net.NetClient)

local function App(): React.Node
    local ctx = React.useContext(HudContext)

    return React.createElement(HudShell, {
        coins = ctx.hud.coins,
        indexFoundJson = ctx.hud.indexFoundJson,
        rewardTrackStartedAt = ctx.hud.rewardTrackStartedAt,
        rewardClaimedJson = ctx.hud.rewardClaimedJson,
        pendingOfflineCoins = ctx.hud.pendingOfflineCoins,
        onClaimReward = function(rewardId: string)
            SoundManager.play("ui_click")
            local result = Zap.ClaimTimedReward.Call(rewardId)
            if not result.success then
                return -1
            end
            return result.coinsGranted or 0
        end,
        onClaimOffline = function()
            SoundManager.play("ui_click")
            local result = Zap.ClaimOfflineEarnings.Call()
            if not result.success then
                SoundManager.play("sell_fail")
            end
        end,
        onDoubleOffline = function()
            SoundManager.play("ui_click")
            local result = Zap.BuyOfflineDouble.Call()
            if not result.success then
                SoundManager.play("sell_fail")
            end
        end,
        onRebirth = function()
            SoundManager.play("ui_click")
            -- Rebirth window ещё нет — см. docs/BACKLOG.md
        end,
    })
end

return App
