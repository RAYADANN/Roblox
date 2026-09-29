--!strict
-- Boot: DI, менеджеры, сеть. Без бизнес-логики.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DevCommands = require(script.core.DevCommands)
local EconomyManager = require(script.core.EconomyManager)
local GameAnalytics = require(script.core.GameAnalytics)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local MonetizationManager = require(script.core.MonetizationManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local ProfileManager = require(script.core.ProfileManager)
local RampManager = require(script.core.RampManager)
local SceneBinder = require(script.core.SceneBinder)
local StandManager = require(script.core.StandManager)
local VfxBroadcaster = require(script.core.VfxBroadcaster)
local Zap = require(script.net.NetServer)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

local profileManager = ProfileManager.new({})

local rampManager: any = nil

local function syncHud(player: Player)
    local data = profileManager:get(player)
    if not data then
        return
    end
    local hud = buildHudPayload.fromPlayerData(data)
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
})

Zap.BuyUpgrade.SetCallback(function(player, upgradeId)
    return economyManager:buyUpgrade(player, upgradeId)
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

Zap.OpenContainer.SetCallback(function(player, slotIndex)
    local ok, err = rampManager:open(player, slotIndex)
    if ok then
        return { success = true, error = nil }
    end
    return { success = false, error = err or "open_failed" }
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

MonetizationManager.new({
    grantProduct = function(player, _productId)
        local ok = profileManager:mutate(player, function(d)
            d.coins += 500
        end)
        if ok then
            syncHud(player)
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
            syncHud(player)
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
})

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
