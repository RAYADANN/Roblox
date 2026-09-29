--!strict
-- HUD state + сеть + React tree.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local ExclusiveOffersData = require(ReplicatedStorage.shared.data.ExclusiveOffers)
local FxKit = require(script.Parent.fx.FxKit)
local HudProvider = require(script.Parent.context.HudProvider)
local MoneyOfferLogic = require(ReplicatedStorage.shared.util.MoneyOfferLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local Notification = require(script.Parent.Parent.core.Notification)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local Zap = require(script.Parent.Parent.net.NetClient)
local theme = require(script.Parent.theme)

local ERROR_TEXT: { [string]: string } = {
    no_coins = "Not enough cash",
    no_slots = "No free slots",
    need_three = "Need 3 matching dummies",
    empty_backpack = "Bag is empty",
    no_cash = "Nothing to collect",
    owned = "Already owned",
    cooldown = "Wait for cooldown",
    cannot_buy = "Can't buy",
    invalid_offer = "Can't claim that offer",
    need_rebirth = "Rebirth for more upgrades",
    need_summons = "Summon more dummies",
    unavailable = "Unavailable",
}

local OK_TEXT: { [string]: string } = {
    bought = "Dummy bought",
    merged = "Merged",
    deposited = "Items sold",
    collected = "Cash collected",
    process = "Sell speed up",
    production = "Higher tier dummies",
    autoCollectEggs = "Auto collect items",
    autoCollectCash = "Auto collect cash",
    doubleItems = "X2 items",
    finished = "Queue finished",
    group = "Group reward",
    rebirthed = "Rebirth complete",
    coins_purchased = "Coins purchased",
    heart_skin = "Heart Skin unlocked",
    rebirth_pack = "Rebirth pack claimed",
}

local function GameRoot(): React.Node
    local hud, setHud = React.useState({
        coins = 0,
        pendingCash = 0,
        backpackEggs = 0,
        luckyBlocks = 0,
        shopQueue = 0,
        processPerSec = 2,
        multiplier = 1,
        unitCount = 0,
        emptySlots = 40,
        nextUnitCost = 1,
        rebirths = 0,
        autoCollectEggs = false,
        autoCollectCash = false,
        doubleItems = false,
        indexMaxTier = 0,
        productionLevel = 0,
        buyCount = 0,
        exclusiveOfferEndsAt = 0,
        exclusiveHeartOwned = false,
        exclusiveRebirthOwned = false,
    } :: NetTypes.HudSyncPayload)
    local rebirthOpen, setRebirthOpen = React.useState(false)
    local indexOpen, setIndexOpen = React.useState(false)
    local tutorialOpen, setTutorialOpen = React.useState(false)
    local tutorialStep, setTutorialStep = React.useState(1)
    local tutorialCoinsAtStep = React.useRef(0)

    React.useEffect(function()
        local cleanups = {
            Zap.PlayerDataSync.On(function(value)
                setHud(NetTypes.fromZapSync(value))
            end),
            Zap.Notify.On(function(payload)
                if payload.kind == "pickup_score" then
                    -- Handled by PickupScoreBridge (boot), not React.
                    return
                elseif payload.kind == "farm_error" then
                    SoundManager.play("sell_fail")
                    Notification.show({
                        text = ERROR_TEXT[payload.payload] or payload.payload,
                        color = theme.Colors.error,
                    })
                elseif payload.kind == "farm_ok" then
                    local isRobuxPurchase = payload.payload == "coins_purchased"
                        or payload.payload == "finished"
                        or payload.payload == "autoCollectEggs"
                        or payload.payload == "autoCollectCash"
                        or payload.payload == "doubleItems"
                        or payload.payload == "heart_skin"
                        or payload.payload == "rebirth_pack"

                    if payload.payload == "deposited" then
                        SoundManager.play("sell_success")
                    elseif payload.payload == "collected" then
                        SoundManager.play("coin_collect")
                    elseif isRobuxPurchase then
                        SoundManager.play("confetti_pop")
                    else
                        SoundManager.play("ui_confirm")
                    end
                    if isRobuxPurchase then
                        FxKit.confetti.play({ count = 420 })
                    end
                    Notification.show({
                        text = OK_TEXT[payload.payload] or payload.payload,
                        color = theme.Colors.success,
                    })
                elseif payload.kind == "upgrade_purchased" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `Upgraded {payload.payload}!`,
                        color = theme.Colors.success,
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
                color = theme.Colors.error,
            })
        end
    end, {})

    local onMoneyOffer = React.useCallback(function(productId: number)
        SoundManager.play("ui_click")
        local player = Players.LocalPlayer
        if typeof(productId) ~= "number" or productId <= 0 or player == nil then
            SoundManager.play("sell_fail")
            Notification.show({
                text = ERROR_TEXT.invalid_offer,
                color = theme.Colors.error,
            })
            return
        end
        if not MoneyOfferLogic.isPackProduct(productId) then
            SoundManager.play("sell_fail")
            Notification.show({
                text = ERROR_TEXT.invalid_offer,
                color = theme.Colors.error,
            })
            return
        end
        MarketplaceService:PromptProductPurchase(player, productId)
    end, {})

    local onExclusiveOffer = React.useCallback(function(offerId: string)
        SoundManager.play("ui_click")
        local offer = ExclusiveOffersData.offerForId(offerId)
        if offer == nil or offer.productKey == "" then
            SoundManager.play("sell_fail")
            Notification.show({
                text = ERROR_TEXT.invalid_offer,
                color = theme.Colors.error,
            })
            return
        end
        local productId = 0
        if offer.productKey == "ExclusivePink" then
            productId = ProductIds.ExclusivePink
        elseif offer.productKey == "ExclusiveRebirthCoins" then
            productId = ProductIds.ExclusiveRebirthCoins
        end
        local player = Players.LocalPlayer
        if productId <= 0 or player == nil then
            Notification.show({
                text = "Exclusive offer — coming soon",
            })
            return
        end
        MarketplaceService:PromptProductPurchase(player, productId)
    end, {})

    local requestRebirth = React.useCallback(function()
        SoundManager.play("ui_click")
        local result = Zap.RequestRebirth.Call()
        if result.success then
            setRebirthOpen(false)
        else
            SoundManager.play("sell_fail")
            Notification.show({
                text = ERROR_TEXT[result.error or ""] or result.error or "Rebirth failed",
                color = theme.Colors.error,
            })
        end
    end, {})

    local onSkipRebirth = React.useCallback(function()
        SoundManager.play("ui_click")
        if ProductIds.SkipRebirth == nil or ProductIds.SkipRebirth <= 0 then
            Notification.show({
                text = "Skip rebirth — coming soon",
            })
            return
        end
        -- Real PromptProductPurchase when SkipRebirth id is configured.
        Notification.show({
            text = "Skip rebirth — coming soon",
        })
    end, {})

    local startTutorial = React.useCallback(function()
        SoundManager.play("ui_click")
        setRebirthOpen(false)
        setIndexOpen(false)
        local result = Zap.RequestStudioReset.Call()
        if result.success then
            tutorialCoinsAtStep.current = 0
            setTutorialStep(1)
            setTutorialOpen(true)
        else
            SoundManager.play("sell_fail")
            Notification.show({
                text = if result.error == "studio_only"
                    then "Tutorial reset — Studio only"
                    else (result.error or "Reset failed"),
                color = theme.Colors.error,
            })
        end
    end, {})

    React.useEffect(function()
        if not tutorialOpen then
            return
        end
        if tutorialStep == 1 and hud.unitCount > 0 then
            setTutorialStep(2)
        elseif tutorialStep == 2 and hud.backpackEggs > 0 then
            setTutorialStep(3)
        elseif tutorialStep == 3 and (hud.shopQueue > 0 or hud.pendingCash > 0) then
            -- Baseline coins when entering cash step — any gain finishes FTUE.
            tutorialCoinsAtStep.current = hud.coins
            setTutorialStep(4)
        elseif tutorialStep == 4 and hud.coins > tutorialCoinsAtStep.current then
            setTutorialOpen(false)
            setTutorialStep(1)
        end
    end, {
        tutorialOpen,
        tutorialStep,
        hud.unitCount,
        hud.backpackEggs,
        hud.shopQueue,
        hud.pendingCash,
        hud.coins,
    })

    local advanceTutorial = React.useCallback(function()
        if tutorialStep >= 4 then
            setTutorialOpen(false)
            setTutorialStep(1)
        else
            setTutorialStep(tutorialStep + 1)
        end
    end, { tutorialStep })

    local skipTutorial = React.useCallback(function()
        setTutorialOpen(false)
        setTutorialStep(1)
    end, {})

    return React.createElement(HudProvider, {
        hud = hud,
        buyUpgrade = buyUpgrade,
        onMoneyOffer = onMoneyOffer,
        onExclusiveOffer = onExclusiveOffer,
        rebirthOpen = rebirthOpen,
        setRebirthOpen = setRebirthOpen,
        indexOpen = indexOpen,
        setIndexOpen = setIndexOpen,
        requestRebirth = requestRebirth,
        onSkipRebirth = onSkipRebirth,
        tutorialOpen = tutorialOpen,
        tutorialStep = tutorialStep,
        startTutorial = startTutorial,
        advanceTutorial = advanceTutorial,
        skipTutorial = skipTutorial,
    }, {
        App = React.createElement(App),
    })
end

return GameRoot
