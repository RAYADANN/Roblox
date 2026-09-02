return {
	["area1 prices"] = function(expect)
		local ShopLogic = require("@shared/util/ShopLogic")
		expect(ShopLogic.price("Area1", "1")).toEqual(1)
		expect(ShopLogic.price("Area1", "2")).toEqual(5)
		expect(ShopLogic.price("Area1", "3")).toEqual(25)
		expect(ShopLogic.price("Area1", "4")).toEqual(100)
		expect(ShopLogic.price("Area1", "5")).toEqual(150)
	end,
	["area2 prices doubled"] = function(expect)
		local ShopLogic = require("@shared/util/ShopLogic")
		expect(ShopLogic.price("Area2", "1")).toEqual(2)
		expect(ShopLogic.price("Area2", "5")).toEqual(300)
	end,
	["canAfford"] = function(expect)
		local ShopLogic = require("@shared/util/ShopLogic")
		expect(ShopLogic.canAfford(5, 5)).toBeTruthy()
		expect(ShopLogic.canAfford(4, 5)).toBeFalsy()
	end,
	["mask roundtrip"] = function(expect)
		local ShopLogic = require("@shared/util/ShopLogic")
		local pads = { ["1"] = true, ["2"] = false, ["3"] = true, ["4"] = false, ["5"] = false }
		local mask = ShopLogic.maskFromPads(pads)
		expect(ShopLogic.maskHasPad(mask, "1")).toBeTruthy()
		expect(ShopLogic.maskHasPad(mask, "2")).toBeFalsy()
		expect(ShopLogic.maskHasPad(mask, "3")).toBeTruthy()
		expect(ShopLogic.allPadsBought(pads)).toBeFalsy()
		expect(ShopLogic.allPadsBought({
			["1"] = true,
			["2"] = true,
			["3"] = true,
			["4"] = true,
			["5"] = true,
		})).toBeTruthy()
		expect(ShopLogic.fullMask()).toEqual(31)
	end,
}
