--!strict
-- Проекция PlayerData → HudPayload.

local PlayerDataModule = if script
	then require(script.Parent.Parent.types.PlayerData)
	else require("@shared/types/PlayerData")
local HudPayloadModule = if script
	then require(script.Parent.Parent.types.HudPayload)
	else require("@shared/types/HudPayload")
local ShopLogic = if script
	then require(script.Parent.ShopLogic)
	else require("@shared/util/ShopLogic")

type PlayerData = PlayerDataModule.PlayerData
type HudPayload = HudPayloadModule.HudPayload

local buildHudPayload = {}

function buildHudPayload.fromPlayerData(data: PlayerData): HudPayload
	return {
		points = data.points,
		shopArea1Mask = ShopLogic.maskFromPads(data.shop.Area1),
		shopArea2Mask = ShopLogic.maskFromPads(data.shop.Area2),
		achBuyAllArea1 = data.achievements.buyAllArea1,
		achBuyAllArea2 = data.achievements.buyAllArea2,
		achFallOffMap = data.achievements.fallOffMap,
		achJumpFive = data.achievements.jumpFiveTimes,
		jumpCount = data.jumpCount,
	}
end

return buildHudPayload
