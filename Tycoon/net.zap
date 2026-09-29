-- Zap schema — единственный источник правды для сети.
-- Генерация: `zap net.zap`

opt server_output = "src/server/net/NetServer.luau"
opt client_output = "src/client/net/NetClient.luau"

event PlayerDataSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		coins: f64,
		pendingCash: f64,
		backpackEggs: f64,
		luckyBlocks: u32,
		shopQueue: f64,
		processPerSec: f32,
		multiplier: f32,
		unitCount: u32,
		emptySlots: u32,
		nextUnitCost: f64,
		rebirths: u32,
		autoCollectEggs: boolean,
		autoCollectCash: boolean,
		doubleItems: boolean,
		indexMaxTier: u32,
		productionLevel: u32,
		buyCount: u32,
		-- 0 = not started; else unix end time for exclusive offer window.
		exclusiveOfferEndsAt: u32,
		exclusiveHeartOwned: boolean,
		exclusiveRebirthOwned: boolean,
	},
}

funct BuyUpgrade = {
	call: Async,
	args: (upgradeId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coins: f64?,
	},
}

funct RequestRebirth = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		rebirths: u32?,
	},
}

-- Studio playtest only (server rejects outside Studio).
funct RequestStudioReset = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

event Notify = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		kind: string.utf8,
		payload: string.utf8,
	},
}

-- Client saw exclusive offer UI → start 72h window once.
event ExclusiveOfferSeen = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: boolean,
}

event PromptGamePass = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: u32,
}

event PlayVfx = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		effectId: string.utf8,
		intensity: f32,
		pos: Vector3?,
		from: Vector3?,
		to: Vector3?,
	},
}
