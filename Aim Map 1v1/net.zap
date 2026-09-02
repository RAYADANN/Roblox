-- Zap schema — единственный источник правды для сети.
-- Генерация: `zap net.zap` (rokit: `red-blox/zap@0.6.29`)

opt server_output = "src/server/net/NetServer.luau"
opt client_output = "src/client/net/NetClient.luau"

event PlayerDataSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		wins: u32,
		losses: u32,
		equippedSkinId: string.utf8,
		lookSensitivity: f32,
		crosshairId: string.utf8,
		ownedSkinIds: string.utf8[],
	},
}

event MatchStateSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		matchId: string.utf8,
		phase: string.utf8,
		firstTo: u8,
		youScore: u8,
		oppScore: u8,
		oppName: string.utf8,
		canRematch: boolean,
		youReadyRematch: boolean,
		oppReadyRematch: boolean,
		visibleSkinId: string.utf8,
		oppVisibleSkinId: string.utf8,
	},
}

funct RequestRematch = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct StartBotMatch = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct SetLookSensitivity = {
	call: Async,
	args: (value: f32),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		lookSensitivity: f32?,
	},
}

funct SetCrosshair = {
	call: Async,
	args: (crosshairId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		crosshairId: string.utf8?,
	},
}

funct SetEquippedSkin = {
	call: Async,
	args: (skinId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		equippedSkinId: string.utf8?,
	},
}

funct FireWeapon = {
	call: Async,
	args: (origin: Vector3, direction: Vector3),
	rets: struct {
		success: boolean,
		hit: boolean,
		killed: boolean,
		error: string.utf8?,
		damage: f32?,
		hitPos: Vector3?,
		headshot: boolean?,
		-- World end of bullet path for local FP tracer (always set on accepted shots).
		traceEnd: Vector3?,
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

event OfferSkinEquip = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		skinId: string.utf8,
		owned: boolean,
	},
}

-- Victim-only: Valorant-style damage direction + vignette cue.
event TookDamage = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		damage: f32,
		headshot: boolean,
		fromPos: Vector3,
	},
}

-- Server → all clients: play a registered VFX preset in the world.
-- pos / from / to are world positions (studs). intensity defaults to 1 on client if 0.
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
		-- Skin id for cosmetic-tinted FX (empty = default tracer).
		skinId: string.utf8?,
	},
}
