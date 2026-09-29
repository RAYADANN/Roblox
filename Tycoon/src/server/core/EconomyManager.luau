--!strict
-- Эталон фичи: покупка апгрейда (Logic → Manager → Net → UI).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameAnalytics = require(script.Parent.GameAnalytics)
local MoneyOfferLogic = require(ReplicatedStorage.shared.util.MoneyOfferLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local ProfileManager = require(script.Parent.ProfileManager)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

type BuyUpgradeResult = NetTypes.BuyUpgradeResult
type HudSyncPayload = NetTypes.HudSyncPayload

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player, payload: HudSyncPayload?) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
    -- World buy pads (red/green) after coins change outside FarmManager.
    refreshPads: ((player: Player) -> ())?,
}

export type EconomyManager = {
    buyUpgrade: (self: EconomyManager, player: Player, upgradeId: string) -> BuyUpgradeResult,
    grantDevProduct: (
        self: EconomyManager,
        player: Player,
        productId: number,
        purchaseId: string
    ) -> boolean,
}

local EconomyManager = {}
EconomyManager.__index = EconomyManager

function EconomyManager.new(deps: Deps)
    return setmetatable({
        _deps = deps,
    }, EconomyManager)
end

function EconomyManager:buyUpgrade(player: Player, upgradeId: string): BuyUpgradeResult
    if typeof(upgradeId) ~= "string" or upgradeId == "" then
        return { success = false, error = "invalid_id" }
    end
    if not UpgradeLogic.isValidId(upgradeId) then
        return { success = false, error = "unknown_upgrade" }
    end

    local profileManager = self._deps.profileManager
    local data = profileManager:get(player)
    if not data then
        return { success = false, error = "no_profile" }
    end

    local level = data.upgrades[upgradeId] or 0
    if UpgradeLogic.isMaxLevel(upgradeId, level) then
        return { success = false, error = "max_level" }
    end

    local cost = UpgradeLogic.cost(upgradeId, level)
    if cost == nil then
        return { success = false, error = "unknown_upgrade" }
    end
    if not UpgradeLogic.canAfford(data.coins, cost) then
        return { success = false, error = "no_coins" }
    end

    local ok = profileManager:mutate(player, function(d)
        d.coins -= cost
        d.upgrades[upgradeId] = level + 1
    end)
    if not ok then
        return { success = false, error = "no_profile" }
    end

    local updated = profileManager:get(player)
    if not updated then
        return { success = false, error = "no_profile" }
    end

    self._deps.syncHud(player, nil)
    self._deps.notify(player, "upgrade_purchased", upgradeId)
    GameAnalytics.log(player, "upgrade_purchase", cost)
    local refreshPads = self._deps.refreshPads
    if refreshPads then
        refreshPads(player)
    end

    return { success = true, error = nil, coins = updated.coins }
end

function EconomyManager:grantDevProduct(
    player: Player,
    productId: number,
    purchaseId: string
): boolean
    if typeof(purchaseId) ~= "string" or purchaseId == "" then
        return false
    end

    local profileManager = self._deps.profileManager
    local data = profileManager:get(player)
    if data == nil then
        return false
    end
    if data.grantedPurchases[purchaseId] == true then
        return true
    end

    local coins = MoneyOfferLogic.coinsForProductId(productId, data.coins)
    if coins == nil then
        return false
    end

    local ok = profileManager:mutate(player, function(d)
        if d.grantedPurchases[purchaseId] == true then
            return
        end
        d.grantedPurchases[purchaseId] = true
        d.coins += coins
    end)
    if not ok then
        return false
    end

    self._deps.syncHud(player, nil)
    self._deps.notify(player, "farm_ok", "coins_purchased")
    GameAnalytics.log(player, "purchase_complete", coins)
    local refreshPads = self._deps.refreshPads
    if refreshPads then
        refreshPads(player)
    end

    return true
end

return EconomyManager
