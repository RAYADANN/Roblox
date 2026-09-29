--!strict
-- Корень: HUD state + сеть + React tree + stand/ramp binders.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local ConveyorVisual = require(script.Parent.Parent.core.ConveyorVisual)
local HeroReveal = require(script.Parent.fx.HeroReveal)
local HudProvider = require(script.Parent.context.HudProvider)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local Notification = require(script.Parent.Parent.core.Notification)
local RampWorldRenderer = require(script.Parent.Parent.core.RampWorldRenderer)
local SlotPromptBinder = require(script.Parent.Parent.core.SlotPromptBinder)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local StandPromptBinder = require(script.Parent.Parent.core.StandPromptBinder)
local Zap = require(script.Parent.Parent.net.NetClient)

local function GameRoot(): React.Node
    local hud, setHud = React.useState({
        coins = 0,
        rebirths = 0,
        upgrades = {},
        handUid = "",
        offersJson = "[]",
        slotsJson = "[]",
        inventoryJson = "[]",
    } :: NetTypes.HudSyncPayload)

    React.useEffect(function()
        local cleanups = {
            Zap.PlayerDataSync.On(function(value)
                local payload = NetTypes.fromZapSync(value)
                setHud(payload)
                StandPromptBinder.setOffersFromJson(payload.offersJson)
                SlotPromptBinder.applyHudSlotsJson(payload.slotsJson)
            end),
            Zap.WorldRampSync.On(function(data)
                RampWorldRenderer.applyJson(data.payloadJson)
            end),
            Zap.MiniSpawned.On(function(data)
                ConveyorVisual.spawn(data.slotIndex, data.heroId, data.travelSec)
            end),
            Zap.Notify.On(function(payload)
                if payload.kind == "rolled" then
                    StandPromptBinder.markSpinAwait()
                    SoundManager.play("ui_confirm")
                elseif payload.kind == "bought" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = "Container bought!",
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "placed" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = "Placed on ramp!",
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "unpacked" then
                    SoundManager.play("ui_confirm")
                    HeroReveal.showFromNotifyPayload(payload.payload)
                elseif payload.kind == "upgrade_purchased" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `Upgraded {payload.payload}!`,
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "error" then
                    SoundManager.play("sell_fail")
                    Notification.show({
                        text = payload.payload,
                        color = Color3.fromRGB(255, 120, 80),
                    })
                end
            end),
        }
        task.defer(function()
            Zap.RequestHudSync.Call()
        end)
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
