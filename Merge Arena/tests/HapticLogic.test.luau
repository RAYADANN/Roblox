--!strict
local HapticLogic = require("../src/shared/vfx/HapticLogic")

return {
	["allows: off или reduceMotion = false"] = function(expect)
		expect(HapticLogic.allows(false, false)).toBeFalsy()
		expect(HapticLogic.allows(true, true)).toBeFalsy()
		expect(HapticLogic.allows(true, false)).toBeTruthy()
	end,

	["strength: Critical > Low"] = function(expect)
		expect(HapticLogic.strength("Critical") > HapticLogic.strength("Low")).toBeTruthy()
	end,

	["profileStrength: Heavy > Light"] = function(expect)
		expect(HapticLogic.profileStrength("Heavy") > HapticLogic.profileStrength("Light")).toBeTruthy()
	end,
}
