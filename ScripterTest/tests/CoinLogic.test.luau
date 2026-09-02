return {
	["spawn cap"] = function(expect)
		local CoinLogic = require("@shared/util/CoinLogic")
		expect(CoinLogic.canSpawn(99)).toBeTruthy()
		expect(CoinLogic.canSpawn(100)).toBeFalsy()
		expect(CoinLogic.pointsPerCoin()).toEqual(1)
	end,
	["colors"] = function(expect)
		local CoinLogic = require("@shared/util/CoinLogic")
		expect(CoinLogic.colorForArea("Area1")).toEqual("yellow")
		expect(CoinLogic.colorForArea("Area2")).toEqual("red")
	end,
	["random offset within bounds"] = function(expect)
		local CoinLogic = require("@shared/util/CoinLogic")
		for _ = 1, 20 do
			local x, z = CoinLogic.randomOffset(82, 82, 3)
			expect(math.abs(x) <= 38).toBeTruthy()
			expect(math.abs(z) <= 38).toBeTruthy()
		end
	end,
}
