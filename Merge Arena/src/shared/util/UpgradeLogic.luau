--!strict

local Constants = if typeof(script) == "Instance"
	then require(script.Parent.Parent.data.Constants)
	else require("../data/Constants")
local UpgradeDatabase = if typeof(script) == "Instance"
	then require(script.Parent.Parent.data.UpgradeDatabase)
	else require("../data/UpgradeDatabase")

type UpgradeId = UpgradeDatabase.UpgradeId

local UpgradeLogic = {}

function UpgradeLogic.cost(upgradeId: string, level: number): number?
	local entry = UpgradeDatabase[upgradeId :: UpgradeId]
	if not entry then
		return nil
	end
	return math.floor(entry.baseCost * Constants.UPGRADE_COST_MULT ^ level)
end

function UpgradeLogic.canAfford(coins: number, cost: number): boolean
	return coins >= cost
end

function UpgradeLogic.isMaxLevel(upgradeId: string, level: number): boolean
	local entry = UpgradeDatabase[upgradeId :: UpgradeId]
	if not entry then
		return true
	end
	return level >= entry.maxLevel
end

function UpgradeLogic.isValidId(upgradeId: string): boolean
	return UpgradeDatabase[upgradeId :: UpgradeId] ~= nil
end

return UpgradeLogic
