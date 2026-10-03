--!strict
-- Robux Limited stands: grant exact hero + mutation + income into inventory/hand.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local IndexLogic = require(ReplicatedStorage.shared.util.IndexLogic)
local LimitedLogic = require(ReplicatedStorage.shared.util.LimitedLogic)
local LimitedOfferDatabase = require(ReplicatedStorage.shared.data.LimitedOfferDatabase)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)
local ProfileManager = require(script.Parent.ProfileManager)

type PlayerData = PlayerDataModule.PlayerData

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
    onStockChanged: ((standId: string, remaining: number, stockMax: number) -> ())?,
}

local LimitedManager = {}
LimitedManager.__index = LimitedManager

function LimitedManager.new(deps: Deps)
    local stock: { [string]: number } = {}
    for _, offer in LimitedOfferDatabase.all() do
        stock[offer.standId] = offer.stockMax
    end
    return setmetatable({
        _deps = deps,
        _stock = stock,
    }, LimitedManager)
end

function LimitedManager:getStock(standId: string): (number, number)
    local offer = LimitedOfferDatabase.get(standId)
    local max = if offer then offer.stockMax else 0
    local selfAny = self :: any
    local left = selfAny._stock[standId]
    if typeof(left) ~= "number" then
        left = max
    end
    return left, max
end

function LimitedManager:canBuy(standId: string, player: Player): (boolean, string?)
    local offer = LimitedOfferDatabase.get(standId)
    if not offer then
        return false, "unknown_stand"
    end
    local left = self:getStock(standId)
    if left <= 0 then
        return false, "sold_out"
    end
    local deps = (self :: any)._deps
    local data = deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    local inv = data.inventory or {}
    if #inv >= Constants.INVENTORY_MAX then
        return false, "inventory_full"
    end
    return true, nil
end

function LimitedManager:grant(player: Player, standId: string): boolean
    local offer = LimitedOfferDatabase.get(standId)
    if not offer then
        Logger.warn("Limited", `unknown stand {standId}`)
        return false
    end
    local okBuy, reason = self:canBuy(standId, player)
    if not okBuy then
        Logger.warn("Limited", `grant blocked {standId}: {reason}`)
        return false
    end

    local deps = (self :: any)._deps
    local selfAny = self :: any
    local granted = false
    local ok = deps.profileManager:mutate(player, function(d: PlayerData)
        if not d.inventory then
            d.inventory = {}
        end
        if #d.inventory >= Constants.INVENTORY_MAX then
            return
        end
        local left = selfAny._stock[standId] or 0
        if left <= 0 then
            return
        end
        selfAny._stock[standId] = left - 1
        local instance = LimitedLogic.buildContainer(offer, HttpService:GenerateGUID(false))
        table.insert(d.inventory, instance)
        if d.handUid == nil or d.handUid == "" then
            d.handUid = instance.uid
        end
        if d.indexFound == nil then
            d.indexFound = {}
        end
        local mutId: string? = if #instance.mutations > 0 then instance.mutations[1] else nil
        IndexLogic.addFound(d.indexFound, instance.heroId, mutId)
        granted = true
    end)

    if not ok or not granted then
        return false
    end

    deps.syncHud(player)
    deps.notify(player, "robux_purchase", offer.heroId)
    local remaining, stockMax = self:getStock(standId)
    if deps.onStockChanged then
        deps.onStockChanged(standId, remaining, stockMax)
    end
    Logger.info("Limited", `granted {offer.heroId} on {standId} to {player.Name}`)
    return true
end

function LimitedManager:grantByProductId(player: Player, productId: number): boolean
    local offer = LimitedOfferDatabase.getByProductId(productId)
    if not offer then
        return false
    end
    return self:grant(player, offer.standId)
end

function LimitedManager:canBuyMegaPack(player: Player): (boolean, string?)
    local deps = (self :: any)._deps
    local data = deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    local need = #LimitedOfferDatabase.all()
    if need <= 0 then
        return false, "no_offers"
    end
    local inv = data.inventory or {}
    if #inv + need > Constants.INVENTORY_MAX then
        return false, "inventory_full"
    end
    return true, nil
end

--- Shop Mega Pack: grant every Limited stand hero into inventory.
function LimitedManager:grantAll(player: Player): boolean
    local okBuy, reason = self:canBuyMegaPack(player)
    if not okBuy then
        Logger.warn("Limited", `mega pack blocked: {reason}`)
        return false
    end

    local deps = (self :: any)._deps
    local selfAny = self :: any
    local grantedIds: { string } = {}
    local ok = deps.profileManager:mutate(player, function(d: PlayerData)
        if not d.inventory then
            d.inventory = {}
        end
        local offers = LimitedOfferDatabase.all()
        if #d.inventory + #offers > Constants.INVENTORY_MAX then
            return
        end
        if d.indexFound == nil then
            d.indexFound = {}
        end
        for _, offer in offers do
            local left = selfAny._stock[offer.standId]
            if typeof(left) == "number" and left > 0 then
                selfAny._stock[offer.standId] = left - 1
            end
            local instance = LimitedLogic.buildContainer(offer, HttpService:GenerateGUID(false))
            table.insert(d.inventory, instance)
            if d.handUid == nil or d.handUid == "" then
                d.handUid = instance.uid
            end
            local mutId: string? = if #instance.mutations > 0 then instance.mutations[1] else nil
            IndexLogic.addFound(d.indexFound, instance.heroId, mutId)
            table.insert(grantedIds, offer.heroId)
        end
    end)

    if not ok or #grantedIds == 0 then
        return false
    end

    deps.syncHud(player)
    deps.notify(player, "robux_purchase", "mega_pack")
    for _, offer in LimitedOfferDatabase.all() do
        local remaining, stockMax = self:getStock(offer.standId)
        if deps.onStockChanged then
            deps.onStockChanged(offer.standId, remaining, stockMax)
        end
    end
    Logger.info("Limited", `mega pack → {player.Name} ({table.concat(grantedIds, ", ")})`)
    return true
end

function LimitedManager.isMegaPackProduct(productId: number): boolean
    local id = (ProductIds :: any).MegaPack
    return typeof(id) == "number" and id > 0 and productId == id
end

return LimitedManager
