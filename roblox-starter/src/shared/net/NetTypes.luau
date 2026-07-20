--!strict
-- Типы HUD-синхронизации (приложение). Zap payload — в net.zap.

export type HudSyncPayload = {
	coins: number,
	rebirths: number,
	upgrades: { [string]: number },
}

export type BuyUpgradeResult = {
	success: boolean,
	error: string?,
	coins: number?,
}

export type NotifyPayload = {
	kind: string,
	payload: string,
}

export type ZapPlayerDataSync = {
	coins: number,
	rebirths: number,
	pickaxe: number,
	backpack: number,
}

local NetTypes = {}

function NetTypes.toZapSync(payload: HudSyncPayload): ZapPlayerDataSync
	return {
		coins = payload.coins,
		rebirths = payload.rebirths,
		pickaxe = payload.upgrades.pickaxe or 0,
		backpack = payload.upgrades.backpack or 0,
	}
end

function NetTypes.fromZapSync(value: ZapPlayerDataSync): HudSyncPayload
	return {
		coins = value.coins,
		rebirths = value.rebirths,
		upgrades = {
			pickaxe = value.pickaxe,
			backpack = value.backpack,
		},
	}
end

return NetTypes
