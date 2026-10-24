-- Zap schema — единственный источник правды для сети.
-- Генерация: `zap net.zap` (rokit: `red-blox/zap@0.6.29`)

opt server_output = "src/server/net/NetServer.luau"
opt client_output = "src/client/net/NetClient.luau"

-- Server → client: монеты и доход владельца.
event PlayerDataSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		coins: f64,
		incomePerSec: f64,
	},
}

-- Server → client: плашки и лента событий (kind — ключ, payload — текст).
event Notify = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		kind: string.utf8,
		payload: string.utf8,
	},
}

-- Server → client: свой персонаж в рэгдолле, клиент задаёт скорость полёта (он сетевой владелец).
event Ragdoll = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		velocity: Vector3,
		duration: f32,
	},
}

-- Server → all clients: play a registered VFX preset in the world.
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

-- Client → server: переключатель крадущегося шага.
event SetSneak = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: boolean,
}

-- Client → server: бросить несомый предмет (Q).
event DropItem = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		_pad: u8,
	},
}
