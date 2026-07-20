--!strict
local QualityLogic = require("../src/shared/vfx/QualityLogic")

return {
	["baseTier: reduceMotion всегда Low"] = function(expect)
		expect(QualityLogic.baseTier({
			touchEnabled = false,
			savedQualityLevel = 10,
			reduceMotion = true,
		})).toEqual("Low")
	end,

	["baseTier: touch + low quality = Low"] = function(expect)
		expect(QualityLogic.baseTier({
			touchEnabled = true,
			savedQualityLevel = 2,
		})).toEqual("Low")
	end,

	["baseTier: desktop high quality = Ultra"] = function(expect)
		expect(QualityLogic.baseTier({
			touchEnabled = false,
			savedQualityLevel = 10,
		})).toEqual("Ultra")
	end,

	["adaptTier: fps падение жёстко режет до Low"] = function(expect)
		expect(QualityLogic.adaptTier("Ultra", 20)).toEqual("Low")
	end,

	["adaptTier: средний fps не даёт Ultra"] = function(expect)
		expect(QualityLogic.adaptTier("Ultra", 35)).toEqual("High")
	end,

	["scaleEmit: уважает maxEmitCount"] = function(expect)
		local budget = QualityLogic.budgetFor("Low")
		local n = QualityLogic.scaleEmit(100, budget)
		expect(n <= budget.maxEmitCount).toBeTruthy()
	end,

	["allowsPriority: Low budget режет Low priority"] = function(expect)
		local budget = QualityLogic.budgetFor("Low")
		expect(QualityLogic.allowsPriority("Low", budget)).toBeFalsy()
		expect(QualityLogic.allowsPriority("Medium", budget)).toBeTruthy()
	end,

	["distanceScale: близко = 1, за max = 0"] = function(expect)
		expect(QualityLogic.distanceScale(10, 100)).toEqual(1)
		expect(QualityLogic.distanceScale(100, 100)).toEqual(0)
		expect(QualityLogic.distanceScale(75, 100) < 1).toBeTruthy()
	end,

	["allowsKind: Low не пускает Loop"] = function(expect)
		local low = QualityLogic.budgetFor("Low")
		expect(QualityLogic.allowsKind("Loop", low)).toBeFalsy()
		expect(QualityLogic.allowsKind("Burst", low)).toBeTruthy()
		local high = QualityLogic.budgetFor("High")
		expect(QualityLogic.allowsKind("Attached", high)).toBeTruthy()
	end,

	["allowsMinTier: Ultra слой не на Medium"] = function(expect)
		local med = QualityLogic.budgetFor("Medium")
		expect(QualityLogic.allowsMinTier("Ultra", med)).toBeFalsy()
		expect(QualityLogic.allowsMinTier("Low", med)).toBeTruthy()
	end,
}
