return {
	["maps player data to hud"] = function(expect)
		local buildHudPayload = require("@shared/util/buildHudPayload")
		local payload = buildHudPayload.fromPlayerData({
			coins = 500,
			rebirths = 2,
			upgrades = { pickaxe = 3 },
			firstSessionComplete = true,
		})
		expect(payload.coins).toEqual(500)
		expect(payload.rebirths).toEqual(2)
		expect(payload.upgrades.pickaxe).toEqual(3)
	end,
}
