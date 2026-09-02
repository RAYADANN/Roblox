--!strict
-- Корень: HUD state + сеть + React tree.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local HudProvider = require(script.Parent.context.HudProvider)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local Notification = require(script.Parent.Parent.core.Notification)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local Zap = require(script.Parent.Parent.net.NetClient)

local function GameRoot(): React.Node
    local hud, setHud =
        React.useState({ coins = 0, rebirths = 0, upgrades = {} } :: NetTypes.HudSyncPayload)

    React.useEffect(function()
        local cleanups = {
            Zap.PlayerDataSync.On(function(value)
                setHud(NetTypes.fromZapSync(value))
            end),
            Zap.Notify.On(function(payload)
                if payload.kind == "upgrade_purchased" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `Upgraded {payload.payload}!`,
                        color = Color3.fromRGB(80, 220, 120),
                    })
                end
            end),
        }
        return function()
            for _, cleanup in cleanups do
                cleanup()
            end
        end
    end, {})

    local buyUpgrade = React.useCallback(function(upgradeId: string)
        SoundManager.play("ui_click")
        local result = Zap.BuyUpgrade.Call(upgradeId)
        if not result.success then
            SoundManager.play("sell_fail")
            Notification.show({
                text = result.error or "Purchase failed",
                color = Color3.fromRGB(255, 120, 80),
            })
        end
    end, {})

    return React.createElement(HudProvider, {
        hud = hud,
        buyUpgrade = buyUpgrade,
    }, {
        App = React.createElement(App),
    })
end

return GameRoot
