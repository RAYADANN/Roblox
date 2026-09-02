--!strict
-- Типы HUD-синхронизации (приложение). Zap payload — в net.zap.

export type HudSyncPayload = {
	points: number,
	shopArea1Mask: number,
	shopArea2Mask: number,
	achBuyAllArea1: boolean,
	achBuyAllArea2: boolean,
	achFallOffMap: boolean,
	achJumpFive: boolean,
	jumpCount: number,
}

export type NotifyPayload = {
	kind: string,
	payload: string,
}

export type ZapPlayerDataSync = {
	points: number,
	shopArea1: number,
	shopArea2: number,
	achBuyAllArea1: boolean,
	achBuyAllArea2: boolean,
	achFallOffMap: boolean,
	achJumpFive: boolean,
	jumpCount: number,
}

local NetTypes = {}

function NetTypes.toZapSync(payload: HudSyncPayload): ZapPlayerDataSync
	return {
		points = payload.points,
		shopArea1 = payload.shopArea1Mask,
		shopArea2 = payload.shopArea2Mask,
		achBuyAllArea1 = payload.achBuyAllArea1,
		achBuyAllArea2 = payload.achBuyAllArea2,
		achFallOffMap = payload.achFallOffMap,
		achJumpFive = payload.achJumpFive,
		jumpCount = payload.jumpCount,
	}
end

function NetTypes.fromZapSync(value: ZapPlayerDataSync): HudSyncPayload
	return {
		points = value.points,
		shopArea1Mask = value.shopArea1,
		shopArea2Mask = value.shopArea2,
		achBuyAllArea1 = value.achBuyAllArea1,
		achBuyAllArea2 = value.achBuyAllArea2,
		achFallOffMap = value.achFallOffMap,
		achJumpFive = value.achJumpFive,
		jumpCount = value.jumpCount,
	}
end

function NetTypes.emptyHud(): HudSyncPayload
	return {
		points = 0,
		shopArea1Mask = 0,
		shopArea2Mask = 0,
		achBuyAllArea1 = false,
		achBuyAllArea2 = false,
		achFallOffMap = false,
		achJumpFive = false,
		jumpCount = 0,
	}
end

return NetTypes
