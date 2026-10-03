--!strict
-- Boot: DI, менеджеры, сеть. Без бизнес-логики.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseClaimManager = require(script.core.BaseClaimManager)
local BoostOfferManager = require(script.core.BoostOfferManager)
local DevCommands = require(script.core.DevCommands)
local EconomyManager = require(script.core.EconomyManager)
local GameAnalytics = require(script.core.GameAnalytics)
local HeroLevelManager = require(script.core.HeroLevelManager)
local HeroTemplateSync = require(script.core.HeroTemplateSync)
local LimitedManager = require(script.core.LimitedManager)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local MonetizationManager = require(script.core.MonetizationManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local OfflineEarningsManager = require(script.core.OfflineEarningsManager)
local ProfileManager = require(script.core.ProfileManager)
local RampManager = require(script.core.RampManager)
local RewardsManager = require(script.core.RewardsManager)
local SceneBinder = require(script.core.SceneBinder)
local SellBoxManager = require(script.core.SellBoxManager)
local SlotMap = require(ReplicatedStorage.shared.util.SlotMap)
local StandManager = require(script.core.StandManager)
local VfxBroadcaster = require(script.core.VfxBroadcaster)
local Zap = require(script.net.NetServer)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

HeroTemplateSync.ensure()

local profileManager = ProfileManager.new({})

local rampManager: any = nil
local sellBoxManager: any = nil
local limitedManager: any = nil
local boostOfferManager: any = nil
local offlineEarningsManager: any = nil
local rewardsManager: any = nil
local baseClaimManager: any = nil

local function syncHud(player: Player)
    local data = profileManager:get(player)
    if not data then
        return
    end
    local hud = buildHudPayload.fromPlayerData(data)
    if rewardsManager ~= nil then
        hud.rewardTrackStartedAt = rewardsManager:getStartedAt(player)
        hud.rewardClaimed = rewardsManager:getClaimed(player)
    end
    Zap.PlayerDataSync.Fire(player, NetTypes.toZapSync(NetTypes.fromHudPayload(hud)))
end

local function publishWorld()
    if rampManager == nil then
        return
    end
    local json = rampManager:buildWorldPayload()
    Zap.WorldRampSync.FireAll({ payloadJson = json })
    SceneBinder.syncHeroPlacePrompts(rampManager:buildPromptStates())
end

baseClaimManager = BaseClaimManager.new({
    onClaimed = function()
        publishWorld()
    end,
    onReleased = function()
        publishWorld()
    end,
})

local economyManager = EconomyManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
})

local standManager = StandManager.new({
    profileManager = profileManager,
})

sellBoxManager = SellBoxManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
})

rewardsManager = RewardsManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
})

rampManager = RampManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    publishWorld = publishWorld,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
    fireMiniSpawned = function(ownerUserId, slotIndex, heroId, payout, travelSec)
        Zap.MiniSpawned.FireAll({
            ownerUserId = ownerUserId,
            slotIndex = slotIndex,
            heroId = heroId,
            payout = payout,
            travelSec = travelSec,
        })
    end,
    depositSellBox = function(player, amount)
        sellBoxManager:deposit(player, amount)
    end,
})

Zap.BuyUpgrade.SetCallback(function(player, upgradeId)
    return economyManager:buyUpgrade(player, upgradeId)
end)

Zap.BuyUpgradeRobux.SetCallback(function(player, upgradeId)
    return economyManager:promptRobuxUpgrade(player, upgradeId)
end)

local heroLevelManager = HeroLevelManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    publishWorld = publishWorld,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
})

Zap.LevelHero.SetCallback(function(player, slotIndex)
    return heroLevelManager:levelUp(player, slotIndex)
end)

Zap.ClaimTimedReward.SetCallback(function(player, rewardId)
    if rewardsManager == nil then
        return { success = false, error = "not_ready", coins = nil, coinsGranted = nil }
    end
    return rewardsManager:claim(player, rewardId)
end)

Zap.CompleteTutorial.SetCallback(function(player)
    local data = profileManager:get(player)
    if not data then
        return { success = false, error = "no_profile" }
    end
    if data.tutorialCompleted then
        return { success = true, error = nil }
    end
    local ok = profileManager:mutate(player, function(d)
        d.tutorialCompleted = true
    end)
    if ok then
        syncHud(player)
        GameAnalytics.log(player, "ftue_complete", 1)
    end
    return { success = ok, error = if ok then nil else "save_failed" }
end)

Zap.ResetTutorial.SetCallback(function(player)
    if not RunService:IsStudio() then
        return { success = false, error = "studio_only" }
    end
    local ok = profileManager:resetProgress(player)
    if ok then
        standManager:ensureOffers(player)
        syncHud(player)
        publishWorld()
    end
    return { success = ok, error = if ok then nil else "save_failed" }
end)

Zap.BoostOfferSeen.SetCallback(function(player, _seen)
    if boostOfferManager then
        boostOfferManager:markSeen(player)
    end
end)

Zap.BuyBoostOffer.SetCallback(function(player, offerId)
    if boostOfferManager == nil then
        return { success = false, error = "not_ready" }
    end
    local ok, err = boostOfferManager:promptBuy(player, offerId)
    return { success = ok, error = err }
end)

Zap.ClaimOfflineEarnings.SetCallback(function(player)
    if offlineEarningsManager == nil then
        return { success = false, error = "not_ready", coinsGranted = nil }
    end
    local ok, err, granted = offlineEarningsManager:claimCurrent(player)
    return {
        success = ok,
        error = err,
        coinsGranted = if ok then granted else nil,
    }
end)

Zap.BuyOfflineDouble.SetCallback(function(player)
    if offlineEarningsManager == nil then
        return { success = false, error = "not_ready" }
    end
    offlineEarningsManager:promptDouble(player)
    return { success = true, error = nil }
end)

Zap.RequestHudSync.SetCallback(function(player)
    syncHud(player)
    return { success = true, error = nil }
end)

Zap.RefreshOffers.SetCallback(function(player)
    local ok = standManager:refreshOffers(player)
    if ok then
        Zap.Notify.Fire(player, { kind = "rolled", payload = "" })
        syncHud(player)
        return { success = true, error = nil }
    end
    return { success = false, error = "refresh_failed" }
end)

Zap.BuyOfferIndex.SetCallback(function(player, offerIndex)
    local ok, err = standManager:buyOfferByIndex(player, offerIndex)
    if ok then
        syncHud(player)
        Zap.Notify.Fire(player, { kind = "bought", payload = tostring(offerIndex) })
        return { success = true, error = nil }
    end
    return { success = false, error = err or "buy_failed" }
end)

Zap.PlaceContainer.SetCallback(function(player, slotIndex)
    local ok, err = rampManager:place(player, slotIndex)
    if ok then
        return { success = true, error = nil }
    end
    return { success = false, error = err or "place_failed" }
end)

Zap.SetHand.SetCallback(function(player, uid)
    local ok, err = standManager:setHand(player, uid)
    if ok then
        syncHud(player)
        return { success = true, error = nil }
    end
    return { success = false, error = err or "set_hand_failed" }
end)

Zap.OpenContainer.SetCallback(function(player, slotIndex)
    local ok, err = rampManager:open(player, slotIndex)
    if ok then
        return { success = true, error = nil }
    end
    return { success = false, error = err or "open_failed" }
end)

Zap.PickupContainer.SetCallback(function(player, slotIndex)
    local ok, err = rampManager:pickup(player, slotIndex)
    if ok then
        return { success = true, error = nil }
    end
    return { success = false, error = err or "pickup_failed" }
end)

profileManager:onLoaded(function(player, data)
    standManager:ensureOffers(player)
    syncHud(player)
    publishWorld()
    GameAnalytics.log(player, "session_start", 1)
    if not data.firstSessionComplete then
        profileManager:mutate(player, function(d)
            d.firstSessionComplete = true
        end)
        GameAnalytics.log(player, "first_action", 1)
    end
end)

local monetizationManager = MonetizationManager.new({
    onSkipUnpack = function(player, slotIndex)
        local ok, err = rampManager:skipUnpack(player, slotIndex)
        if not ok then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "skip_failed" })
            return false
        end
        Zap.Notify.Fire(player, { kind = "robux_purchase", payload = "skip_unpack" })
        return true
    end,
    findPackingSlot = function(player)
        local data = profileManager:get(player)
        if not data or not data.slots then
            return nil
        end
        local Constants = require(ReplicatedStorage.shared.data.Constants)
        for i = 1, Constants.SLOT_COUNT do
            local slot = SlotMap.get(data.slots, i)
            if slot and not slot.unpacked and (slot.unpackProgress or 0) < 0.999 then
                return slot.slotIndex or i
            end
        end
        return nil
    end,
    onLimitedPurchase = function(player, standId)
        if limitedManager == nil then
            return false
        end
        local okBuy, err = limitedManager:canBuy(standId, player)
        if not okBuy then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "buy_failed" })
            return false
        end
        return limitedManager:grant(player, standId)
    end,
    onMegaPackPurchase = function(player)
        if limitedManager == nil then
            return false
        end
        local okBuy, err = limitedManager:canBuyMegaPack(player)
        if not okBuy then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "buy_failed" })
            return false
        end
        return limitedManager:grantAll(player)
    end,
    onGamePassPurchase = function(player, gamePassId)
        if MonetizationManager.isMegaPackGamePass(gamePassId) then
            if limitedManager == nil then
                return false
            end
            -- Already owns all limited → still ok (idempotent).
            local okBuy = limitedManager:canBuyMegaPack(player)
            if not okBuy then
                return true
            end
            return limitedManager:grantAll(player)
        end
        if boostOfferManager and boostOfferManager:grantByProductId(player, gamePassId) then
            return true
        end
        return false
    end,
    onCoinPackPurchase = function(player, coins)
        local ok = profileManager:mutate(player, function(d)
            d.coins += coins
        end)
        if ok then
            syncHud(player)
            Zap.Notify.Fire(player, { kind = "robux_purchase", payload = "coin_pack" })
            Zap.Notify.Fire(player, { kind = "income", payload = tostring(coins) })
        end
        return ok
    end,
    onSkipAllRewards = function(player)
        if rewardsManager == nil then
            return false
        end
        return rewardsManager:skipAll(player)
    end,
    grantProduct = function(player, productId)
        if MonetizationManager.isSkipUnpackProduct(productId) then
            return monetizationManager:grantSkipUnpack(player)
        end
        if monetizationManager:grantLimitedFromReceipt(player, productId) then
            return true
        end
        if monetizationManager:grantCoinPackFromReceipt(player, productId) then
            return true
        end
        if monetizationManager:grantSkipAllFromReceipt(player, productId) then
            return true
        end
        if economyManager:grantByProductId(player, productId) then
            return true
        end
        if offlineEarningsManager and OfflineEarningsManager.isOfflineDoubleProduct(productId) then
            local ok = offlineEarningsManager:claimDouble(player)
            if ok then
                Zap.Notify.Fire(player, { kind = "robux_purchase", payload = "offline_double" })
            end
            return ok
        end
        Logger.warn("Monetization", `unhandled product {productId} for {player.Name}`)
        return false
    end,
})
monetizationManager:start()

Zap.BuyMegaPack.SetCallback(function(player)
    if limitedManager == nil then
        return { success = false, error = "not_ready" }
    end
    local okBuy, err = limitedManager:canBuyMegaPack(player)
    if not okBuy then
        return { success = false, error = err or "buy_failed" }
    end
    monetizationManager:promptMegaPack(player)
    return { success = true, error = nil }
end)

Zap.BuySkipAllRewards.SetCallback(function(player)
    monetizationManager:promptSkipAllRewards(player)
    return { success = true, error = nil }
end)

Zap.BuyCoinPack.SetCallback(function(player, packId)
    local ok, err = monetizationManager:promptCoinPack(player, packId)
    return { success = ok, error = err }
end)

boostOfferManager = BoostOfferManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
})

offlineEarningsManager = OfflineEarningsManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
})

limitedManager = LimitedManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
    onStockChanged = function(standId, remaining, stockMax)
        SceneBinder.setLimitedStock(standId, remaining, stockMax)
    end,
})

DevCommands.start({
    mutateCoins = function(player, delta)
        local ok = profileManager:mutate(player, function(d)
            d.coins += delta
        end)
        if ok then
            syncHud(player)
        end
        return ok
    end,
    resetTutorial = function(player)
        local ok = profileManager:resetProgress(player)
        if ok then
            standManager:ensureOffers(player)
            syncHud(player)
            publishWorld()
        end
        return ok
    end,
})

SceneBinder.install({
    onRoll = function(player)
        standManager:refreshOffers(player)
        -- Notify first so client marks spin-await before PlayerDataSync lands.
        Zap.Notify.Fire(player, { kind = "rolled", payload = "" })
        syncHud(player)
    end,
    onBuy = function(player, offerIndex)
        local ok, err = standManager:buyOfferByIndex(player, offerIndex)
        if ok then
            syncHud(player)
            Zap.Notify.Fire(player, { kind = "bought", payload = tostring(offerIndex) })
        else
            Zap.Notify.Fire(player, { kind = "error", payload = err or "buy_failed" })
        end
    end,
    onPlace = function(player, slotIndex)
        rampManager:place(player, slotIndex)
    end,
    onOpen = function(player, slotIndex)
        local ok, err = rampManager:open(player, slotIndex)
        if not ok then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "open_failed" })
        end
    end,
    onSkipUnpack = function(player, slotIndex)
        monetizationManager:promptSkipUnpack(player, slotIndex)
    end,
    onPickup = function(player, slotIndex)
        local ok, err = rampManager:pickup(player, slotIndex)
        if not ok then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "pickup_failed" })
        end
    end,
    onTakeSellBox = function(player)
        local ok, err = sellBoxManager:pickup(player)
        if not ok then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "take_failed" })
        end
    end,
    onSellCrates = function(player)
        local ok, err = sellBoxManager:sellAll(player)
        if not ok then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "sell_failed" })
        end
    end,
    onBuyLimited = function(player, standId)
        local okBuy, err = limitedManager:canBuy(standId, player)
        if not okBuy then
            Zap.Notify.Fire(player, { kind = "error", payload = err or "buy_failed" })
            return
        end
        monetizationManager:promptLimited(player, standId)
    end,
    ownsInstance = function(player, inst)
        return baseClaimManager:ownsInstance(player, inst)
    end,
})

baseClaimManager:start()
publishWorld()

rampManager:start()
profileManager:start()

if RunService:IsStudio() then
    task.spawn(function()
        while true do
            task.wait(4.5)
            local lab = workspace:FindFirstChild("VfxLab")
            if lab then
                local fromPart = lab:FindFirstChild("ProjectileStart")
                local toPart = lab:FindFirstChild("ProjectileEnd")
                if fromPart and fromPart:IsA("BasePart") and toPart and toPart:IsA("BasePart") then
                    VfxBroadcaster.castBoltImpact(fromPart.Position, toPart.Position, 1.1)
                end
            end
        end
    end)
end

Logger.info("server", "boot complete")
