--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")

local Constants = require(shared.constants)
local OreTypes = require(shared.types.OreTypes)
local UpgradeLogic = require(shared.util.UpgradeLogic)

export type BuyResult = {
    success: boolean,
    upgradeId: string?,
    newLevel: number?,
    coinsSpent: number?,
    error: string?,
    message: string?,
    messageParams: { [string]: any }?,
}

local BuyUpgrade = {}

local function getLevel(playerData: OreTypes.PlayerData, upgradeId: string): number
    local field = UpgradeLogic.levelField(upgradeId)
    if not field then
        return 0
    end
    return (playerData :: any)[field] or 1
end

function BuyUpgrade.execute(playerData: OreTypes.PlayerData, upgradeId: string): BuyResult
    local cfg = Constants.UPGRADES[upgradeId]
    if not cfg then
        return { success = false, error = "unknown_upgrade", message = "server.error.unknownUpgrade" }
    end

    local currentLevel = getLevel(playerData, upgradeId)

    -- Phase 9: maxLevel у pickaxe растёт с количеством ребёртов
    -- (см. RebirthLogic.pickaxeMaxLevelBonus). UpgradeLogic.maxLevel —
    -- единственный источник, чтобы клиентский tooltip и сервер совпадали.
    local effectiveMax = UpgradeLogic.maxLevel(upgradeId, playerData.rebirths or 0)
    if currentLevel >= effectiveMax then
        return { success = false, error = "max_level", message = "server.error.maxLevel" }
    end

    local cost = UpgradeLogic.upgradeCost(upgradeId, currentLevel)
    local coins = playerData.coins or 0
    if coins < cost then
        return {
            success = false,
            error = "not_enough_coins",
            message = "server.error.notEnoughCoins",
            messageParams = { amount = cost - coins },
        }
    end

    local field = UpgradeLogic.levelField(upgradeId)
    if not field then
        return { success = false, error = "invalid_upgrade", message = "server.error.invalidUpgrade" }
    end

    playerData.coins -= cost
    local newLevel = currentLevel + 1
    local data = playerData :: any
    data[field] = newLevel

    return {
        success = true,
        upgradeId = upgradeId,
        newLevel = newLevel,
        coinsSpent = cost,
        message = "server.success.levelUp",
        messageParams = { level = newLevel },
    }
end

return BuyUpgrade
