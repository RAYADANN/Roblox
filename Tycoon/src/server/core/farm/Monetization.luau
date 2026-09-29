--!strict
-- Gamepasses + Finish Now DevProduct grants / prompts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExclusiveOfferLogic = require(ReplicatedStorage.shared.util.ExclusiveOfferLogic)
local FarmLogic = require(ReplicatedStorage.shared.util.FarmLogic)
local FinishNowLogic = require(ReplicatedStorage.shared.util.FinishNowLogic)
local GameAnalytics = require(script.Parent.Parent.GameAnalytics)
local GamepassLogic = require(ReplicatedStorage.shared.util.GamepassLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local RebirthLogic = require(ReplicatedStorage.shared.util.RebirthLogic)
local StandHeartVisuals = require(script.Parent.Parent.StandHeartVisuals)

local Types = require(script.Parent.Types)

type FarmHost = Types.FarmHost

local Monetization = {}

local function applyHeartVisual(self: FarmHost, player: Player, owned: boolean)
    local session = self._sessions[player]
    if session == nil then
        return
    end
    StandHeartVisuals.apply(session.plot.island, owned)
end

function Monetization.grantGamepass(
    self: FarmHost,
    player: Player,
    gamepassId: number,
    fromPurchase: boolean?
): boolean
    local pass = GamepassLogic.passForGamepassId(gamepassId)
    if pass == nil then
        return false
    end
    if fromPurchase ~= true and not self._deps.ownsGamepass(player, gamepassId) then
        return false
    end
    local data = self:_data(player)
    if data == nil then
        return false
    end
    local had = if pass.field == "autoCollectEggs"
        then data.autoCollectEggs
        elseif pass.field == "autoCollectCash" then data.autoCollectCash
        else data.doubleItems
    if had then
        return true
    end
    local ok = self._deps.profileManager:mutate(player, function(d)
        if pass.field == "autoCollectEggs" then
            d.autoCollectEggs = true
        elseif pass.field == "autoCollectCash" then
            d.autoCollectCash = true
        else
            d.doubleItems = true
        end
    end)
    if not ok then
        return false
    end
    self:_sync(player)
    self._deps.notify(player, "farm_ok", pass.field)
    if fromPurchase == true then
        GameAnalytics.log(player, "purchase_complete", pass.robux)
    end
    return true
end

function Monetization.reconcileGamepasses(self: FarmHost, player: Player)
    for _, pass in GamepassLogic.passes() do
        if self._deps.ownsGamepass(player, pass.gamepassId) then
            self:grantGamepass(player, pass.gamepassId)
        end
    end
end

function Monetization.tryGamepassPad(self: FarmHost, player: Player, action: string)
    local field = GamepassLogic.fieldForAction(action)
    if field == nil then
        return
    end
    local pass = GamepassLogic.passForField(field)
    if pass == nil or pass.gamepassId <= 0 then
        self._deps.notify(player, "farm_error", "cannot_buy")
        return
    end
    local data = self:_data(player)
    if data == nil then
        return
    end
    local owned = if field == "autoCollectEggs"
        then data.autoCollectEggs
        elseif field == "autoCollectCash" then data.autoCollectCash
        else data.doubleItems
    if owned then
        self._deps.notify(player, "farm_error", "owned")
        return
    end
    self._deps.promptGamepass(player, pass.gamepassId)
end

function Monetization.tryFinishNow(self: FarmHost, player: Player)
    local data = self:_data(player)
    if data == nil or data.shopQueue <= 0 then
        return
    end
    if FinishNowLogic.productId() <= 0 then
        self._deps.notify(player, "farm_error", "unavailable")
        return
    end
    self._deps.promptDevProduct(player, "FinishNow")
end

function Monetization.grantFinishNow(self: FarmHost, player: Player, purchaseId: string): boolean
    if typeof(purchaseId) ~= "string" or purchaseId == "" then
        return false
    end
    local data = self:_data(player)
    if data == nil then
        return false
    end
    if data.grantedPurchases[purchaseId] == true then
        return true
    end

    local ok = self._deps.profileManager:mutate(player, function(d)
        if d.grantedPurchases[purchaseId] == true then
            return
        end
        d.grantedPurchases[purchaseId] = true
        if d.shopQueue > 0 then
            d.pendingCash += FarmLogic.cashFromEggs(d.shopQueue, d.rebirths)
            d.shopQueue = 0
        end
    end)
    if not ok then
        return false
    end

    self:_sync(player)
    self._deps.notify(player, "farm_ok", "finished")
    GameAnalytics.log(player, "purchase_complete", FinishNowLogic.ROBUX)
    return true
end

function Monetization.grantExclusiveHeart(
    self: FarmHost,
    player: Player,
    purchaseId: string
): boolean
    if typeof(purchaseId) ~= "string" or purchaseId == "" then
        return false
    end
    local data = self:_data(player)
    if data == nil then
        return false
    end
    if data.grantedPurchases[purchaseId] == true or data.exclusiveHeartOwned == true then
        applyHeartVisual(self, player, true)
        return true
    end

    local ok = self._deps.profileManager:mutate(player, function(d)
        if d.grantedPurchases[purchaseId] == true then
            return
        end
        d.grantedPurchases[purchaseId] = true
        d.exclusiveHeartOwned = true
    end)
    if not ok then
        return false
    end

    applyHeartVisual(self, player, true)
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "heart_skin")
    GameAnalytics.log(player, "purchase_complete", 99)
    return true
end

function Monetization.clearExclusiveHeart(self: FarmHost, player: Player): boolean
    local data = self:_data(player)
    if data == nil then
        return false
    end
    if data.exclusiveHeartOwned ~= true then
        applyHeartVisual(self, player, false)
        return true
    end
    local ok = self._deps.profileManager:mutate(player, function(d)
        d.exclusiveHeartOwned = false
    end)
    if not ok then
        return false
    end
    applyHeartVisual(self, player, false)
    self:_sync(player)
    Logger.info("FarmManager", `cleared Heart Skin → {player.Name}`)
    return true
end

--- Studio / test: wipe exclusive offers + 72h window so both packs show again.
function Monetization.clearExclusiveOffers(self: FarmHost, player: Player): boolean
    local data = self:_data(player)
    if data == nil then
        return false
    end
    local ok = self._deps.profileManager:mutate(player, function(d)
        d.exclusiveHeartOwned = false
        d.exclusiveRebirthOwned = false
        d.exclusiveOfferSeenAt = 0
    end)
    if not ok then
        return false
    end
    applyHeartVisual(self, player, false)
    self:_sync(player)
    Logger.info("FarmManager", `cleared exclusive offers → {player.Name}`)
    return true
end

function Monetization.grantExclusiveRebirth(
    self: FarmHost,
    player: Player,
    purchaseId: string
): boolean
    if typeof(purchaseId) ~= "string" or purchaseId == "" then
        return false
    end
    local session = self._sessions[player]
    local data = self:_data(player)
    if data == nil then
        return false
    end
    if data.grantedPurchases[purchaseId] == true or data.exclusiveRebirthOwned == true then
        return true
    end

    if session and (session.pendingEggs > 0 or session.pendingLucky > 0) then
        self:_flushBag(player, session)
    end

    local ok = self._deps.profileManager:mutate(player, function(d)
        if d.grantedPurchases[purchaseId] == true then
            return
        end
        d.grantedPurchases[purchaseId] = true
        d.exclusiveRebirthOwned = true
        RebirthLogic.apply(d)
        d.coins += ExclusiveOfferLogic.rebirthPackBonusCoins(d.rebirths)
    end)
    if not ok then
        return false
    end

    if session then
        for _, drop in session.drops do
            if drop.Parent ~= nil then
                drop:Destroy()
            end
        end
        table.clear(session.drops)
        session.pendingEggs = 0
        session.pendingLucky = 0
        session.bagFlushQueued = false
        data = self:_data(player)
        if data then
            self:_syncUnits(session, data)
        end
    end

    self:_sync(player)
    self._deps.notify(player, "farm_ok", "rebirth_pack")
    GameAnalytics.log(player, "purchase_complete", 25)
    return true
end

function Monetization.refreshExclusiveHeart(self: FarmHost, player: Player)
    local data = self:_data(player)
    applyHeartVisual(self, player, data ~= nil and data.exclusiveHeartOwned == true)
end

function Monetization.clearGamepasses(self: FarmHost, player: Player): boolean
    local ok = self._deps.profileManager:mutate(player, function(d)
        d.autoCollectEggs = false
        d.autoCollectCash = false
        d.doubleItems = false
    end)
    if not ok then
        return false
    end
    self:_sync(player)
    Logger.info("FarmManager", `cleared gamepasses → {player.Name}`)
    return true
end

return Monetization
