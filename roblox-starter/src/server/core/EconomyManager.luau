--!strict
-- Эталон фичи: покупка апгрейда (Logic → Manager → Net → UI).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)
local GameAnalytics = require(script.Parent.GameAnalytics)
local ProfileManager = require(script.Parent.ProfileManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

type PlayerData = require(ReplicatedStorage.shared.types.PlayerData).PlayerData
type BuyUpgradeResult = NetTypes.BuyUpgradeResult
type HudSyncPayload = NetTypes.HudSyncPayload

export type Deps = {
	profileManager: ProfileManager.ProfileManager,
	syncHud: (player: Player, payload: HudSyncPayload) -> (),
	notify: (player: Player, kind: string, payload: string) -> (),
}

local EconomyManager = {}
EconomyManager.__index = EconomyManager

function EconomyManager.new(deps: Deps)
	return setmetatable({ _deps = deps }, EconomyManager)
end

local function toHud(data: PlayerData): HudSyncPayload
	local payload = buildHudPayload.fromPlayerData(data)
	return {
		coins = payload.coins,
		rebirths = payload.rebirths,
		upgrades = payload.upgrades,
	}
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

	self._deps.syncHud(player, toHud(updated))
	self._deps.notify(player, "upgrade_purchased", upgradeId)
	GameAnalytics.log(player, "upgrade_purchase", cost)

	return { success = true, error = nil, coins = updated.coins }
end

return EconomyManager
