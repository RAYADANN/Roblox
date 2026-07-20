--!strict
-- Пустой драйвер: reduce motion, cutscene lock, или «камера не наша».

local CameraTypes = require(script.Parent.Types)

export type CameraDriver = CameraTypes.CameraDriver

local NoopDriver = {}
NoopDriver.__index = NoopDriver

function NoopDriver.new(): CameraDriver
	return setmetatable({
		shake = function(_self, _a, _d, _r) end,
		setRumble = function(_self, _a, _r) end,
		isSupported = function(_self)
			return false
		end,
		destroy = function(_self) end,
	}, NoopDriver) :: any
end

return NoopDriver
