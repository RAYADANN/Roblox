--!strict
-- Active pad SellBox + inventory crates. Coins only after SellGuy sell.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local SellBoxLogic = require(ReplicatedStorage.shared.util.SellBoxLogic)

type PlayerData = PlayerDataModule.PlayerData
type SellCrate = SellBoxLogic.SellCrate

export type Deps = {
    profileManager: {
        get: (self: any, player: Player) -> PlayerData?,
        mutate: (self: any, player: Player, fn: (data: PlayerData) -> ()) -> boolean,
    },
    syncHud: (player: Player) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
}

local SellBoxManager = {}
SellBoxManager.__index = SellBoxManager

local function ensureFields(d: PlayerData)
    if d.activeSellBox == nil then
        d.activeSellBox = SellBoxLogic.emptyActive()
    end
    if d.sellCrates == nil then
        d.sellCrates = {}
    end
end

function SellBoxManager.new(deps: Deps)
    return setmetatable({
        _deps = deps,
    }, SellBoxManager)
end

function SellBoxManager:deposit(player: Player, amount: number): boolean
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local data = pm:get(player)
    if not data then
        return false
    end
    local ok = pm:mutate(player, function(d: PlayerData)
        ensureFields(d)
        d.activeSellBox = SellBoxLogic.deposit(d.activeSellBox, amount, 1)
    end)
    if ok then
        deps.syncHud(player)
    end
    return ok
end

function SellBoxManager:pickup(player: Player): (boolean, string?)
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local data = pm:get(player)
    if not data then
        return false, "no_profile"
    end
    ensureFields(data)
    if not SellBoxLogic.canPickup(data.activeSellBox) then
        return false, "sellbox_empty"
    end
    if #(data.sellCrates or {}) >= Constants.SELL_CRATE_MAX then
        return false, "sellbox_inventory_full"
    end

    local failReason: string? = nil
    local ok = pm:mutate(player, function(d: PlayerData)
        ensureFields(d)
        if not SellBoxLogic.canPickup(d.activeSellBox) then
            failReason = "sellbox_empty"
            return
        end
        if #d.sellCrates >= Constants.SELL_CRATE_MAX then
            failReason = "sellbox_inventory_full"
            return
        end
        local crate: SellCrate = {
            uid = HttpService:GenerateGUID(false),
            coins = d.activeSellBox.coins,
            depositCount = d.activeSellBox.depositCount,
        }
        table.insert(d.sellCrates, crate)
        d.activeSellBox = SellBoxLogic.emptyActive()
    end)

    if not ok then
        return false, "mutate_failed"
    end
    if failReason then
        return false, failReason
    end

    deps.syncHud(player)
    deps.notify(player, "sellbox_picked", "")
    return true, nil
end

function SellBoxManager:sellAll(player: Player): (boolean, string?, number?)
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local data = pm:get(player)
    if not data then
        return false, "no_profile", nil
    end
    ensureFields(data)
    local total = SellBoxLogic.totalCrateCoins(data.sellCrates or {})
    if total <= 0 then
        return false, "no_crates", nil
    end

    local paid = 0
    local ok = pm:mutate(player, function(d: PlayerData)
        ensureFields(d)
        local raw = SellBoxLogic.totalCrateCoins(d.sellCrates)
        if raw <= 0 then
            return
        end
        local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
        local BoostOfferLogic = require(ReplicatedStorage.shared.util.BoostOfferLogic)
        paid = raw * UpgradeLogic.cashMultiplier(d.upgrades) * BoostOfferLogic.cashMultiplier(d)
        d.coins += paid
        d.sellCrates = {}
    end)

    if not ok or paid <= 0 then
        return false, "no_crates", nil
    end

    deps.syncHud(player)
    deps.notify(player, "income", tostring(math.floor(paid + 0.5)))
    return true, nil, paid
end

return SellBoxManager
