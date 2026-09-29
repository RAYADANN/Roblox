--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local modules = ReplicatedStorage:WaitForChild("Packages")

local Logger = require(shared.util.Logger)
local Net = require(modules.Net)
local OreTypes = require(shared.types.OreTypes)

local ProfileManager = require(script.Parent.ProfileManager)
local SellInventory = require(script.Parent.economy.SellInventory)
local BuyUpgrade = require(script.Parent.economy.BuyUpgrade)
local GameAnalytics = require(script.Parent.GameAnalytics)
local RetentionAnalytics = require(script.Parent.RetentionAnalytics)

export type Deps = {
    profileManager: typeof(ProfileManager.new()),
    oreDatabase: SellInventory.OreDatabaseLike,
    onEconomyChanged: ((player: Player) -> ())?,
}

local EconomyManager = {}
EconomyManager.__index = EconomyManager

local function isBaseUpgrades(data: OreTypes.PlayerData): boolean
	return (data.pickaxeLevel or 1) == 1
		and (data.speedLevel or 1) == 1
		and (data.fortuneLevel or 1) == 1
		and (data.inventoryLevel or 1) == 1
		and (data.critLevel or 1) == 1
		and (data.multiSellLevel or 1) == 1
		and data.autoSellUnlocked ~= true
end

function EconomyManager.new(deps: Deps)
    local self = setmetatable({}, EconomyManager)
    self._log = Logger.new("EconomyManager")
    self._profileManager = deps.profileManager
    self._oreDatabase = deps.oreDatabase
    self._onEconomyChanged = deps.onEconomyChanged

    Net:Handle("BuyUpgrade", function(player, upgradeId)
        return self:buyUpgrade(player, upgradeId)
    end)

    Net:Handle("SellOres", function(player)
        return self:sellAll(player)
    end)

    self._log:info("EconomyManager initialized")
    return self
end

function EconomyManager:_syncPlayer(player: Player)
    if self._onEconomyChanged then
        self._onEconomyChanged(player)
    end
end

function EconomyManager:_getData(player: Player): OreTypes.PlayerData?
    return self._profileManager:getData(player)
end

function EconomyManager:sellAll(player: Player)
    local playerData = self:_getData(player)
    if not playerData then
        return { success = false, error = "no_profile", message = "server.error.noProfile" }
    end

    local isFirstSell = (playerData.totalCoinsEarned or 0) == 0
    local result = SellInventory.execute(self._oreDatabase, playerData)
    if result.success then
        self._log:info("Sold ores for", player.UserId, "- coins:", result.coinsEarned, "items:", result.itemsSold)
        GameAnalytics.track(player, "sell_ores", result.coinsEarned or 0)
        RetentionAnalytics.onSell(player)
        if isFirstSell then
            GameAnalytics.track(player, "first_sell", result.coinsEarned or 1)
        end
        self:_syncPlayer(player)
    end

    return result
end

function EconomyManager:buyUpgrade(player: Player, upgradeId: string)
    if type(upgradeId) ~= "string" then
        return { success = false, error = "invalid_request", message = "server.error.invalidRequest" }
    end

    local playerData = self:_getData(player)
    if not playerData then
        return { success = false, error = "no_profile", message = "server.error.noProfile" }
    end

    local isFirstUpgrade = isBaseUpgrades(playerData)
    local result = BuyUpgrade.execute(playerData, upgradeId)
    if result.success then
        self._log:info("Upgrade bought:", player.UserId, upgradeId, "->", result.newLevel)
        GameAnalytics.track(player, "upgrade_" .. upgradeId, result.newLevel or 1)
        RetentionAnalytics.onUpgrade(player)
        if isFirstUpgrade then
            GameAnalytics.track(player, "first_upgrade", 1)
        end
        self:_syncPlayer(player)
    end

    return result
end

function EconomyManager:addCoins(player: Player, amount: number): boolean
    if amount <= 0 then
        return false
    end
    local playerData = self:_getData(player)
    if not playerData then
        return false
    end
    playerData.coins = (playerData.coins or 0) + amount
    self:_syncPlayer(player)
    return true
end

function EconomyManager:removeCoins(player: Player, amount: number): boolean
    if amount <= 0 then
        return false
    end
    local playerData = self:_getData(player)
    if not playerData then
        return false
    end
    if (playerData.coins or 0) < amount then
        return false
    end
    playerData.coins -= amount
    self:_syncPlayer(player)
    return true
end

return EconomyManager
