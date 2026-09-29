--!strict
-- Boot: DI, Showroom managers, Zap. No business logic here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AuctionManager = require(script.core.AuctionManager)
local DevCommands = require(script.core.DevCommands)
local DispenserManager = require(script.core.DispenserManager)
local ExhibitManager = require(script.core.ExhibitManager)
local GameAnalytics = require(script.core.GameAnalytics)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local MonetizationManager = require(script.core.MonetizationManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PlotManager = require(script.core.PlotManager)
local ProfileManager = require(script.core.ProfileManager)
local WorldCosmeticPublisher = require(script.core.WorldCosmeticPublisher)
local Zap = require(script.net.NetServer)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

local profileManager = ProfileManager.new({})
local plotManager = PlotManager.new()
local auctionManager: AuctionManager.AuctionManager

local function syncHud(player: Player, payload: NetTypes.HudSyncPayload?)
    local data = profileManager:get(player)
    if not data then
        return
    end
    local hud = if payload then payload else buildHudPayload.fromPlayerData(data, os.time())
    Zap.PlayerDataSync.Fire(player, NetTypes.toZapSync(hud))
end

local function publishWorld(pubs: { NetTypes.WorldExhibitPub })
    auctionManager:appendAuctionPubs(pubs)
    local json = NetTypes.encodeWorld(pubs)
    for _, player in Players:GetPlayers() do
        Zap.WorldExhibitsSync.Fire(player, { payloadJson = json })
    end
end

local function notify(player: Player, kind: string, payload: string)
    Zap.Notify.Fire(player, { kind = kind, payload = payload })
end

local dispenserManager = DispenserManager.new({
    profileManager = profileManager,
})

local exhibitManager = ExhibitManager.new({
    profileManager = profileManager,
    plotManager = plotManager,
    syncHud = syncHud,
    publishWorld = publishWorld,
    notify = notify,
})

auctionManager = AuctionManager.new({
    profileManager = profileManager,
    plotManager = plotManager,
    syncHud = function(player)
        syncHud(player, nil)
    end,
    publishWorld = function()
        exhibitManager:publishAll()
    end,
    notify = notify,
    fireAuctionSync = function(player, payload)
        Zap.AuctionSync.Fire(player, payload)
    end,
})

Zap.PickOffer.SetCallback(function(player, offerUid)
    local ok, err = dispenserManager:pickOffer(player, offerUid)
    if ok then
        syncHud(player, nil)
        notify(player, "picked", offerUid)
    end
    return { success = ok, error = err }
end)

Zap.PickOfferIndex.SetCallback(function(player, offerIndex)
    local ok, err = dispenserManager:pickOfferByIndex(player, offerIndex)
    if ok then
        syncHud(player, nil)
        notify(player, "picked", tostring(offerIndex))
    end
    return { success = ok, error = err }
end)

Zap.RequestHudSync.SetCallback(function(player)
    local data = profileManager:get(player)
    if not data then
        return { success = false, error = "no_profile" }
    end
    dispenserManager:ensureOffers(player)
    syncHud(player, nil)
    exhibitManager:publishAll()
    auctionManager:onProfileLoaded(player)
    return { success = true, error = nil }
end)

Zap.PlaceExhibit.SetCallback(function(player, slotIndex)
    local ok, err = exhibitManager:place(player, slotIndex)
    return { success = ok, error = err }
end)

Zap.RemoveExhibit.SetCallback(function(player, slotIndex)
    local ok, err = exhibitManager:removeToHand(player, slotIndex)
    return { success = ok, error = err }
end)

Zap.SellExhibit.SetCallback(function(player, slotIndex)
    local ok, err, coins = exhibitManager:sell(player, slotIndex)
    return { success = ok, error = err, coins = coins }
end)

Zap.MoveToFavorite.SetCallback(function(player, slotIndex)
    local ok, err = exhibitManager:moveToFavorite(player, slotIndex)
    return { success = ok, error = err }
end)

Zap.CollectFavoriteBank.SetCallback(function(player)
    local ok, err, coins = exhibitManager:collectFavoriteBank(player)
    return { success = ok, error = err, coins = coins }
end)

Zap.ReactExhibit.SetCallback(function(player, ownerUserId, slotIndex)
    local ok, err = exhibitManager:react(player, ownerUserId, slotIndex)
    return { success = ok, error = err }
end)

Zap.RefreshOffers.SetCallback(function(player)
    local ok = dispenserManager:refreshOffers(player)
    if ok then
        syncHud(player, nil)
    end
    return { success = ok, error = if ok then nil else "refresh_failed" }
end)

Zap.SelectHand.SetCallback(function(player, itemUid)
    local ok, err = exhibitManager:selectHand(player, itemUid)
    return { success = ok, error = err }
end)

Zap.StartAuction.SetCallback(function(player, slotIndex, fromFavorite)
    local ok, err = auctionManager:start(player, slotIndex, fromFavorite)
    return { success = ok, error = err }
end)

Zap.ConfirmAuctionSell.SetCallback(function(player)
    local ok, err, coins = auctionManager:confirmSell(player)
    return { success = ok, error = err, coins = coins }
end)

Zap.RerunAuction.SetCallback(function(player)
    local ok, err = auctionManager:rerun(player)
    return { success = ok, error = err }
end)

plotManager:bindPlaceButtons(function(player, slotIndex)
    local ok, err = exhibitManager:place(player, slotIndex)
    if not ok then
        notify(player, "place_fail", err or "Cannot place")
    else
        notify(player, "placed", tostring(slotIndex))
    end
end)

plotManager:bindFavoriteCollect(function(player)
    local ok, err, amount = exhibitManager:collectFavoriteBank(player)
    if not ok then
        if err ~= "empty_bank" then
            notify(player, "collect_fail", err or "Cannot collect")
        end
    else
        notify(player, "collect", tostring(amount or 0))
    end
end)

profileManager:onLoaded(function(player, data)
    local plot = plotManager:claim(player)
    if plot then
        profileManager:mutate(player, function(d)
            d.plotId = plot.id
        end)
        task.defer(function()
            plotManager:teleportToPlot(player)
        end)
    end
    dispenserManager:ensureOffers(player)
    syncHud(player, buildHudPayload.fromPlayerData(profileManager:get(player) or data, os.time()))
    exhibitManager:publishAll()
    WorldCosmeticPublisher.syncHeldEgg(player, profileManager:get(player) or data)
    auctionManager:onProfileLoaded(player)
    GameAnalytics.log(player, "session_start", 1)
    if not data.firstSessionComplete then
        profileManager:mutate(player, function(d)
            d.firstSessionComplete = true
        end)
        GameAnalytics.log(player, "first_action", 1)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    plotManager:release(player)
    auctionManager:clearPlayer(player)
    exhibitManager:publishAll()
end)

MonetizationManager.new({
    grantProduct = function(player, _productId)
        local ok = profileManager:mutate(player, function(d)
            d.coins += 500
        end)
        if ok then
            syncHud(player, nil)
        end
        return ok
    end,
}):start()

DevCommands.start({
    mutateCoins = function(player, delta)
        local ok = profileManager:mutate(player, function(d)
            d.coins += delta
        end)
        if ok then
            syncHud(player, nil)
        end
        return ok
    end,
})

exhibitManager:start()
auctionManager:startTicking()
WorldCosmeticPublisher.startHeldEgg()
profileManager:start()

Logger.info("server", "showroom boot complete")
