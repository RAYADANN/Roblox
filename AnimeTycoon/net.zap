-- Zap schema — AnimeTycoon network.
-- Generate: `zap net.zap`

opt server_output = "src/server/net/NetServer.luau"
opt client_output = "src/client/net/NetClient.luau"

event PlayerDataSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		coins: f64,
		rebirths: u32,
		pickaxe: u32,
		backpack: u32,
		handUid: string.utf8,
		offersJson: string.utf8,
		slotsJson: string.utf8,
		inventoryJson: string.utf8,
	},
}

-- World snapshot: all ramp slots (JSON) for every client.
event WorldRampSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		payloadJson: string.utf8,
	},
}

funct RequestHudSync = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct RefreshOffers = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct BuyOfferIndex = {
	call: Async,
	args: (offerIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct PlaceContainer = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct OpenContainer = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
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

event Notify = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		kind: string.utf8,
		payload: string.utf8,
	},
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

-- Mini spawned on conveyor (visual cue; coins granted on arrive server-side).
event MiniSpawned = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		ownerUserId: u32,
		slotIndex: u8,
		heroId: string.utf8,
		payout: f64,
		travelSec: f32,
	},
}
