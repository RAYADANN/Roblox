-- Zap schema — единственный источник правды для сети.
-- Генерация: `zap net.zap`

opt server_output = "src/server/net/NetServer.luau"
opt client_output = "src/client/net/NetClient.luau"

event PlayerDataSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		points: f64,
		shopArea1: u8,
		shopArea2: u8,
		achBuyAllArea1: boolean,
		achBuyAllArea2: boolean,
		achFallOffMap: boolean,
		achJumpFive: boolean,
		jumpCount: u8,
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

event AchievementUnlocked = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		id: string.utf8,
	},
}

event CoinCollected = {
	from: Server,
	type: Unreliable,
	call: ManyAsync,
	data: struct {
		x: f32,
		y: f32,
		z: f32,
		isRed: boolean,
	},
}
