return {
	["maps player data to hud"] = function(expect)
		local buildHudPayload = require("@shared/util/buildHudPayload")
		local payload = buildHudPayload.fromPlayerData({
			points = 42,
			shop = {
				Area1 = { ["1"] = true, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false },
				Area2 = { ["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false },
			},
			achievements = {
				buyAllArea1 = false,
				buyAllArea2 = false,
				fallOffMap = true,
				jumpFiveTimes = false,
			},
			jumpCount = 3,
			firstSessionComplete = true,
		})
		expect(payload.points).toEqual(42)
		expect(payload.shopArea1Mask).toEqual(1)
		expect(payload.achFallOffMap).toBeTruthy()
		expect(payload.jumpCount).toEqual(3)
	end,
}
