-- Zap schema — единственный источник правды для сети.
-- Генерация: `zap net.zap` (rokit: `red-blox/zap@0.6.29`)

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
	},
}
