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
