--!strict
-- Проекция PlayerData → HudPayload. Pure, тестируемо.

export type PlayerData = require(script.Parent.Parent.types.PlayerData).PlayerData
export type HudPayload = require(script.Parent.Parent.types.HudPayload).HudPayload

local buildHudPayload = {}

function buildHudPayload.fromPlayerData(data: PlayerData): HudPayload
	return {
		coins = data.coins,
		rebirths = data.rebirths,
		upgrades = table.clone(data.upgrades),
	}
end

return buildHudPayload
