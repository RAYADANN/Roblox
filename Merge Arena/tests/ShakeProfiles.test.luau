--!strict
local ShakeProfiles = require("../src/shared/vfx/ShakeProfiles")

return {
	["resolve: Light/Medium/Heavy"] = function(expect)
		local light = ShakeProfiles.resolve("Light")
		local heavy = ShakeProfiles.resolve("Heavy")
		expect(light ~= nil).toBeTruthy()
		expect(heavy ~= nil).toBeTruthy()
		expect((heavy :: any).amplitude > (light :: any).amplitude).toBeTruthy()
	end,

	["resolve: unknown = nil"] = function(expect)
		expect(ShakeProfiles.resolve("Nope")).toEqual(nil)
	end,
}
