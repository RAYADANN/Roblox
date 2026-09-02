return {
	["jump five"] = function(expect)
		local AchievementLogic = require("@shared/util/AchievementLogic")
		expect(AchievementLogic.shouldUnlockJumpFive(4)).toBeFalsy()
		expect(AchievementLogic.shouldUnlockJumpFive(5)).toBeTruthy()
	end,
	["fall threshold"] = function(expect)
		local AchievementLogic = require("@shared/util/AchievementLogic")
		expect(AchievementLogic.shouldUnlockFall(-49)).toBeFalsy()
		expect(AchievementLogic.shouldUnlockFall(-50)).toBeTruthy()
	end,
	["buy all"] = function(expect)
		local AchievementLogic = require("@shared/util/AchievementLogic")
		expect(AchievementLogic.shouldUnlockBuyAll("Area1", {
			["1"] = true,
			["2"] = true,
			["3"] = true,
			["4"] = true,
			["5"] = false,
		})).toBeFalsy()
		expect(AchievementLogic.shouldUnlockBuyAll("Area1", {
			["1"] = true,
			["2"] = true,
			["3"] = true,
			["4"] = true,
			["5"] = true,
		})).toBeTruthy()
		expect(AchievementLogic.areaAchievementId("Area2")).toEqual("buyAllArea2")
	end,
}
