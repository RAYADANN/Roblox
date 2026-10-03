--!strict
-- Эталон фичи: покупка апгрейда (Logic → Manager → Net → UI).

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameAnalytics = require(script.Parent.GameAnalytics)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

type PlayerData = PlayerDataModule.PlayerData
type BuyUpgradeResult = NetTypes.BuyUpgradeResult

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
}

local EconomyManager = {}
EconomyManager.__index = EconomyManager

function EconomyManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, EconomyManager)
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

    self._deps.syncHud(player)
    self._deps.notify(player, "upgrade_purchased", upgradeId)
    GameAnalytics.log(player, "upgrade_purchase", cost)

    return { success = true, error = nil, coins = updated.coins }
end

--- +1 level without coins (DevProduct receipt / Studio mock).
function EconomyManager:grantRobuxUpgrade(player: Player, upgradeId: string): boolean
    if not UpgradeLogic.isValidId(upgradeId) then
        return false
    end
    local profileManager = self._deps.profileManager
    local data = profileManager:get(player)
    if not data then
        return false
    end
    local level = data.upgrades[upgradeId] or 0
    if UpgradeLogic.isMaxLevel(upgradeId, level) then
        Logger.warn("Economy", `Robux upgrade {upgradeId} already max for {player.Name}`)
        -- Consume receipt so Roblox does not retry forever.
        return true
    end

    local ok = profileManager:mutate(player, function(d)
        local cur = d.upgrades[upgradeId] or 0
        if UpgradeLogic.isMaxLevel(upgradeId, cur) then
            return
        end
        d.upgrades[upgradeId] = cur + 1
    end)
    if not ok then
        return false
    end

    self._deps.syncHud(player)
    self._deps.notify(player, "upgrade_purchased", upgradeId)
    self._deps.notify(player, "robux_purchase", upgradeId)
    GameAnalytics.log(player, "upgrade_robux", 1)
    Logger.info("Economy", `Robux +1 {upgradeId} → {player.Name}`)
    return true
end

function EconomyManager:grantByProductId(player: Player, productId: number): boolean
    local upgradeId = UpgradeLogic.idFromProductId(productId)
    if not upgradeId then
        return false
    end
    return self:grantRobuxUpgrade(player, upgradeId)
end

function EconomyManager:promptRobuxUpgrade(player: Player, upgradeId: string): BuyUpgradeResult
    if typeof(upgradeId) ~= "string" or upgradeId == "" then
        return { success = false, error = "invalid_id" }
    end
    if not UpgradeLogic.isValidId(upgradeId) then
        return { success = false, error = "unknown_upgrade" }
    end

    local data = self._deps.profileManager:get(player)
    if not data then
        return { success = false, error = "no_profile" }
    end
    local level = data.upgrades[upgradeId] or 0
    if UpgradeLogic.isMaxLevel(upgradeId, level) then
        return { success = false, error = "max_level" }
    end

    local productId = UpgradeLogic.productId(upgradeId)
    if productId == nil then
        if RunService:IsStudio() then
            Logger.info("Economy", `Studio mock Robux upgrade {upgradeId} for {player.Name}`)
            local ok = self:grantRobuxUpgrade(player, upgradeId)
            return { success = ok, error = if ok then nil else "grant_failed" }
        end
        return { success = false, error = "product_unset" }
    end

    MarketplaceService:PromptProductPurchase(player, productId)
    return { success = true, error = nil }
end

return EconomyManager
