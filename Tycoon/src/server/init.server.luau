--!strict
-- Boot: DI, менеджеры, сеть. Без бизнес-логики.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local DevCommands = require(script.core.DevCommands)
local EconomyManager = require(script.core.EconomyManager)
local ExclusiveOfferLogic = require(ReplicatedStorage.shared.util.ExclusiveOfferLogic)
local FarmManager = require(script.core.FarmManager)
local FinishNowLogic = require(ReplicatedStorage.shared.util.FinishNowLogic)
local GameAnalytics = require(script.core.GameAnalytics)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local MonetizationManager = require(script.core.MonetizationManager)
local MultiplierService = require(script.core.MultiplierService)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PadBinder = require(script.core.PadBinder)
local PlotRegistry = require(script.core.PlotRegistry)
local ProfileManager = require(script.core.ProfileManager)
local Zap = require(script.net.NetServer)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

local profileManager = ProfileManager.new({})
local plotRegistry = PlotRegistry.new()
plotRegistry:start()

local multiplierService
local farmManager

local function slotCap(player: Player): number
    if farmManager == nil then
        return Constants.MAX_SLOTS
    end
    local n = farmManager:slotCount(player)
    if n == nil then
        return Constants.MAX_SLOTS
    end
    return n
end

local function syncHud(player: Player, payload: NetTypes.HudSyncPayload?)
    local data = profileManager:get(player)
    if not data then
        return
    end
    local hud = if payload
        then payload
        else buildHudPayload.fromPlayerData(data, multiplierService:get(), slotCap(player))
    Zap.PlayerDataSync.Fire(player, NetTypes.toZapSync(hud))
end

multiplierService = MultiplierService.new({
    onChanged = function()
        for _, player in Players:GetPlayers() do
            syncHud(player, nil)
        end
    end,
})

farmManager = FarmManager.new({
    profileManager = profileManager,
    plotRegistry = plotRegistry,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
    playVfx = function(player, effectId, intensity, from, to)
        Zap.PlayVfx.Fire(player, {
            effectId = effectId,
            intensity = intensity,
            from = from,
            to = to,
        })
    end,
    getMultiplier = function()
        return multiplierService:get()
    end,
    ownsGamepass = MonetizationManager.owns,
    promptGamepass = function(player, gamepassId)
        Zap.PromptGamePass.Fire(player, gamepassId)
    end,
    promptDevProduct = function(player, productKey)
        MonetizationManager.promptDevProduct(player, productKey)
    end,
})

local economyManager = EconomyManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    notify = function(player, kind, pl)
        Zap.Notify.Fire(player, { kind = kind, payload = pl })
    end,
    refreshPads = function(player)
        farmManager:refreshPads(player)
    end,
})

Zap.BuyUpgrade.SetCallback(function(player, upgradeId)
    return economyManager:buyUpgrade(player, upgradeId)
end)

Zap.RequestRebirth.SetCallback(function(player)
    return farmManager:tryRebirth(player)
end)

Zap.ExclusiveOfferSeen.SetCallback(function(player, _seen)
    local data = profileManager:get(player)
    if data == nil then
        return
    end
    if (data.exclusiveOfferSeenAt or 0) > 0 then
        return
    end
    profileManager:mutate(player, function(d)
        if (d.exclusiveOfferSeenAt or 0) <= 0 then
            d.exclusiveOfferSeenAt = os.time()
        end
    end)
    syncHud(player, nil)
end)

Zap.RequestStudioReset.SetCallback(function(player)
    if not RunService:IsStudio() then
        return { success = false, error = "studio_only" }
    end
    local ok = farmManager:resetToStart(player)
    return { success = ok, error = if ok then nil else "no_session" }
end)

profileManager:onLoaded(function(player, data)
    farmManager:bindPlayer(player)
    syncHud(player, buildHudPayload.fromPlayerData(data, multiplierService:get(), slotCap(player)))
    GameAnalytics.log(player, "session_start", 1)
    if not data.firstSessionComplete then
        profileManager:mutate(player, function(d)
            d.firstSessionComplete = true
        end)
        GameAnalytics.log(player, "first_action", 1)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    farmManager:unbindPlayer(player)
end)

MonetizationManager.new({
    grantProduct = function(player, productId, purchaseId)
        if FinishNowLogic.isProduct(productId) then
            return farmManager:grantFinishNow(player, purchaseId)
        end
        if ExclusiveOfferLogic.isPinkProduct(productId) then
            return farmManager:grantExclusiveHeart(player, purchaseId)
        end
        if ExclusiveOfferLogic.isRebirthProduct(productId) then
            return farmManager:grantExclusiveRebirth(player, purchaseId)
        end
        return economyManager:grantDevProduct(player, productId, purchaseId)
    end,
    grantGamepass = function(player, gamepassId, fromPurchase)
        return farmManager:grantGamepass(player, gamepassId, fromPurchase)
    end,
}):start()

DevCommands.start({
    mutateCoins = function(player, delta)
        local ok = profileManager:mutate(player, function(d)
            d.coins += delta
        end)
        if ok then
            syncHud(player, nil)
            farmManager:refreshPads(player)
        end
        return ok
    end,
    resetProfile = function(player)
        return farmManager:resetToStart(player)
    end,
    clearGamepasses = function(player)
        return farmManager:clearGamepasses(player)
    end,
    clearExclusiveHeart = function(player)
        return farmManager:clearExclusiveHeart(player)
    end,
    clearExclusiveOffers = function(player)
        return farmManager:clearExclusiveOffers(player)
    end,
})

multiplierService:start()
farmManager:start()
PadBinder.start({
    farmManager = farmManager,
    plotRegistry = plotRegistry,
})
profileManager:start()

if RunService:IsStudio() then
    local ServerStorage = game:GetService("ServerStorage")
    local old = ServerStorage:FindFirstChild("StudioResetProfile")
    if old then
        old:Destroy()
    end
    local ev = Instance.new("BindableEvent")
    ev.Name = "StudioResetProfile"
    ev.Event:Connect(function()
        for _, player in Players:GetPlayers() do
            farmManager:resetToStart(player)
        end
    end)
    ev.Parent = ServerStorage

    local oldEx = ServerStorage:FindFirstChild("StudioClearExclusiveOffers")
    if oldEx then
        oldEx:Destroy()
    end
    local clearEx = Instance.new("BindableEvent")
    clearEx.Name = "StudioClearExclusiveOffers"
    clearEx.Event:Connect(function()
        for _, player in Players:GetPlayers() do
            farmManager:clearExclusiveOffers(player)
        end
    end)
    clearEx.Parent = ServerStorage

    -- MCP execute_luau cannot Fire BindableEvent (capabilities).
    -- Bump these Attributes to a *positive* value to trigger; boot set-to-0 must not reset.
    ServerStorage:SetAttribute("ClearExclusiveOffers", 0)
    ServerStorage:GetAttributeChangedSignal("ClearExclusiveOffers"):Connect(function()
        local v = ServerStorage:GetAttribute("ClearExclusiveOffers")
        if typeof(v) ~= "number" or v <= 0 then
            return
        end
        for _, player in Players:GetPlayers() do
            farmManager:clearExclusiveOffers(player)
        end
    end)

    ServerStorage:SetAttribute("StudioFullReset", 0)
    ServerStorage:GetAttributeChangedSignal("StudioFullReset"):Connect(function()
        local v = ServerStorage:GetAttribute("StudioFullReset")
        if typeof(v) ~= "number" or v <= 0 then
            return
        end
        for _, player in Players:GetPlayers() do
            farmManager:clearExclusiveOffers(player)
            farmManager:resetToStart(player)
        end
    end)
end

Logger.info("server", "boot complete")
