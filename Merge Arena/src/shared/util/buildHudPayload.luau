--!strict
-- Проекция PlayerData → HudPayload. Pure, тестируемо.

local PlayerDataMod = if typeof(script) == "Instance"
	then require(script.Parent.Parent.types.PlayerData)
	else require("../types/PlayerData")
local HudPayloadMod = if typeof(script) == "Instance"
	then require(script.Parent.Parent.types.HudPayload)
	else require("../types/HudPayload")

export type PlayerData = PlayerDataMod.PlayerData
export type HudPayload = HudPayloadMod.HudPayload

local buildHudPayload = {}

function buildHudPayload.fromPlayerData(data: PlayerData): HudPayload
	return {
		coins = data.coins,
		rebirths = data.rebirths,
		upgrades = table.clone(data.upgrades),
	}
end

return buildHudPayload
