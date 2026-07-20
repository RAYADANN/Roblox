return {
	["cost level 0 pickaxe"] = function(expect)
		local UpgradeLogic = require("@shared/util/UpgradeLogic")
		expect(UpgradeLogic.cost("pickaxe", 0)).toEqual(100)
	end,
	["rejects unknown upgrade"] = function(expect)
		local UpgradeLogic = require("@shared/util/UpgradeLogic")
		expect(UpgradeLogic.cost("unknown", 0)).toBe(nil)
	end,
	["max level detection"] = function(expect)
		local UpgradeLogic = require("@shared/util/UpgradeLogic")
		expect(UpgradeLogic.isMaxLevel("pickaxe", 50)).toBe(true)
		expect(UpgradeLogic.isMaxLevel("pickaxe", 49)).toBe(false)
	end,
}
