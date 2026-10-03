--!strict
-- Корень: HUD state + сеть + React tree + stand/ramp binders.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local BasePromptGate = require(script.Parent.Parent.core.BasePromptGate)
local ConveyorVisual = require(script.Parent.Parent.core.ConveyorVisual)
local FloorUnlockCutscene = require(script.Parent.Parent.core.FloorUnlockCutscene)
local FloorUnlockVisual = require(script.Parent.Parent.core.FloorUnlockVisual)
local FxKit = require(script.Parent.fx.FxKit)
local HandToolBinder = require(script.Parent.Parent.core.HandToolBinder)
local HeroReveal = require(script.Parent.fx.HeroReveal)
local HudProvider = require(script.Parent.context.HudProvider)
local MoneyGainFx = require(script.Parent.fx.MoneyGainFx)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local Notification = require(script.Parent.Parent.core.Notification)
local PadTierCutscene = require(script.Parent.Parent.core.PadTierCutscene)
local PadUnlockCutscene = require(script.Parent.Parent.core.PadUnlockCutscene)
local Players = game:GetService("Players")
local RampWorldRenderer = require(script.Parent.Parent.core.RampWorldRenderer)
local SellBoxPromptBinder = require(script.Parent.Parent.core.SellBoxPromptBinder)
local SellTableBoard = require(script.Parent.Parent.core.SellTableBoard)
local SlotPromptBinder = require(script.Parent.Parent.core.SlotPromptBinder)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local SpeedBoostVisual = require(script.Parent.Parent.core.SpeedBoostVisual)
local StandPadTierVisual = require(script.Parent.Parent.core.StandPadTierVisual)
local StandPromptBinder = require(script.Parent.Parent.core.StandPromptBinder)
local StandUnlockVisual = require(script.Parent.Parent.core.StandUnlockVisual)
local TutorialController = require(script.Parent.Parent.core.TutorialController)
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
        sellBoxCoins = 0,
        sellBoxDeposits = 0,
        sellCratesJson = "[]",
        indexFoundJson = "[]",
        rewardTrackStartedAt = 0,
        rewardClaimedJson = "[]",
        tutorialCompleted = false,
        boostOfferEndsAt = 0,
        ownsLuckyX2 = false,
        ownsLuckyX4 = false,
        ownsMoneyX2 = false,
        pendingOfflineCoins = 0,
    } :: NetTypes.HudSyncPayload)

    React.useEffect(function()
        -- Hide locked floors/beams/pads before first sync (default: floor 1, Stand1).
        FloorUnlockVisual.apply({})
        StandUnlockVisual.apply({})
        SpeedBoostVisual.apply({})

        local prevUpgrades: { [string]: number } = {}
        local hudPrimed = false
        local cleanups = {
            Zap.PlayerDataSync.On(function(value)
                local payload = NetTypes.fromZapSync(value)
                setHud(payload)
                if hudPrimed then
                    StandUnlockVisual.notePadIncrease(prevUpgrades, payload.upgrades)
                    StandPadTierVisual.noteTierIncrease(prevUpgrades, payload.upgrades)
                    FloorUnlockVisual.noteFloorIncrease(prevUpgrades, payload.upgrades)
                else
                    hudPrimed = true
                end
                prevUpgrades = table.clone(payload.upgrades)
                StandUnlockVisual.apply(payload.upgrades)
                StandPadTierVisual.apply(payload.upgrades)
                StandPromptBinder.applyUpgrades(payload.upgrades)
                StandPromptBinder.setOffersFromJson(payload.offersJson)
                SlotPromptBinder.applyHudSlotsJson(payload.slotsJson)
                SlotPromptBinder.applyUpgrades(payload.upgrades)
                FloorUnlockVisual.apply(payload.upgrades)
                SpeedBoostVisual.apply(payload.upgrades)
                SellTableBoard.applySlotsJson(payload.slotsJson)
                SellBoxPromptBinder.applyHud(
                    payload.sellBoxCoins,
                    payload.sellBoxDeposits,
                    payload.sellCratesJson
                )
                HandToolBinder.apply(
                    payload.inventoryJson,
                    payload.sellCratesJson,
                    payload.handUid or ""
                )
                BasePromptGate.refresh()
                TutorialController.applyHud({
                    offersJson = payload.offersJson,
                    slotsJson = payload.slotsJson,
                    inventoryJson = payload.inventoryJson,
                    handUid = payload.handUid,
                    sellBoxCoins = payload.sellBoxCoins,
                    sellCratesJson = payload.sellCratesJson,
                })
                TutorialController.syncCompleted(payload.tutorialCompleted)
                if payload.tutorialCompleted or TutorialController.isDoneLocal() then
                    TutorialController.stop()
                elseif not TutorialController.isActive() then
                    TutorialController.start(function()
                        task.spawn(function()
                            Zap.CompleteTutorial.Call()
                        end)
                    end)
                end
            end),
            Zap.WorldRampSync.On(function(data)
                RampWorldRenderer.applyJson(data.payloadJson)
                BasePromptGate.refresh()
            end),
            Zap.MiniSpawned.On(function(data)
                local localPlayer = Players.LocalPlayer
                local forLocal = localPlayer ~= nil and data.ownerUserId == localPlayer.UserId
                ConveyorVisual.spawn(
                    data.slotIndex,
                    data.heroId,
                    data.travelSec,
                    data.ownerUserId,
                    forLocal
                )
            end),
            Zap.Notify.On(function(payload)
                TutorialController.onNotify(payload.kind)
                if payload.kind == "rolled" then
                    StandPromptBinder.markSpinAwait()
                    SoundManager.play("ui_confirm")
                elseif payload.kind == "bought" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = "Container bought!",
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "boost_owned" then
                    SoundManager.play("confetti_pop")
                    FxKit.confetti.play({ count = 420 })
                    Notification.show({
                        text = "Boost unlocked!",
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "robux_purchase" then
                    SoundManager.play("confetti_pop")
                    FxKit.confetti.play({ count = 420 })
                    Notification.show({
                        text = "Purchase complete!",
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
                elseif payload.kind == "sellbox_picked" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = "Sell Box taken!",
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "income" then
                    local amount = tonumber(payload.payload) or 0
                    MoneyGainFx.play({
                        amount = amount,
                        from = MoneyGainFx.screenFromInstance(BaseLayout.getSellGuy()),
                    })
                    Notification.show({
                        text = `Sold for ${math.floor(amount + 0.5)}!`,
                        color = Color3.fromRGB(255, 220, 80),
                    })
                elseif payload.kind == "offline_claimed" then
                    local amount = tonumber(payload.payload) or 0
                    if amount > 0 then
                        MoneyGainFx.play({ amount = amount })
                    end
                    Notification.show({
                        text = `Offline +${math.floor(amount + 0.5)}!`,
                        color = Color3.fromRGB(255, 220, 80),
                    })
                elseif payload.kind == "hero_leveled" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `Hero Lv {payload.payload}`,
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "upgrade_purchased" then
                    SoundManager.play("ui_confirm")
                    if payload.payload == "pad" then
                        local padIndex = StandUnlockVisual.getPendingPad()
                        if padIndex then
                            PadUnlockCutscene.playAsync(padIndex)
                        else
                            Notification.show({
                                text = "Pad unlocked!",
                                color = Color3.fromRGB(80, 220, 120),
                            })
                        end
                    elseif payload.payload == "padTier" then
                        if StandPadTierVisual.getHoldTier() ~= nil then
                            PadTierCutscene.playAsync()
                        else
                            StandPadTierVisual.reapply()
                            Notification.show({
                                text = "Pads upgraded!",
                                color = Color3.fromRGB(80, 220, 120),
                            })
                        end
                    elseif payload.payload == "base" then
                        local floorIndex = FloorUnlockVisual.getPendingFloor()
                        if floorIndex and floorIndex > 1 then
                            FloorUnlockCutscene.playAsync(floorIndex)
                        else
                            Notification.show({
                                text = "Upgraded base!",
                                color = Color3.fromRGB(80, 220, 120),
                            })
                        end
                    else
                        Notification.show({
                            text = `Upgraded {payload.payload}!`,
                            color = Color3.fromRGB(80, 220, 120),
                        })
                    end
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
            TutorialController.stop()
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

    local onBoostOffer = React.useCallback(function(offerId: string)
        SoundManager.play("ui_click")
        local result = Zap.BuyBoostOffer.Call(offerId)
        if not result.success then
            SoundManager.play("sell_fail")
            Notification.show({
                text = result.error or "Offer unavailable",
                color = Color3.fromRGB(255, 120, 80),
            })
        end
    end, {})

    local onBoostOfferSeen = React.useCallback(function()
        Zap.BoostOfferSeen.Fire(true)
    end, {})

    return React.createElement(HudProvider, {
        hud = hud,
        buyUpgrade = buyUpgrade,
        onBoostOffer = onBoostOffer,
        onBoostOfferSeen = onBoostOfferSeen,
    }, {
        App = React.createElement(App),
    })
end

return GameRoot
