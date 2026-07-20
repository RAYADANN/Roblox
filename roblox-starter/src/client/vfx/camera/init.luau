--!strict
-- Фабрика camera drivers. См. docs/VFX_ENGINE.md § Camera.

local CameraTypes = require(script.Types)
local HumanoidOffsetDriver = require(script.HumanoidOffsetDriver)
local ShakeBusDriver = require(script.ShakeBusDriver)
local NoopDriver = require(script.NoopDriver)

export type CameraDriver = CameraTypes.CameraDriver
export type CameraMode = CameraTypes.CameraMode
export type ShakeBusDriver = ShakeBusDriver.ShakeBusDriver

local Camera = {}

export type ResolveConfig = {
	mode: CameraMode?,
	--- Готовый драйвер (полный контроль игры).
	driver: CameraDriver?,
	--- Для ShakeBus: каждый кадр отдаём offset в твой camera script.
	onShakeOffset: ((Vector3) -> ())?,
}

function Camera.resolve(config: ResolveConfig?): CameraDriver
	if config and config.driver then
		return config.driver
	end
	local mode: CameraMode = if config and config.mode then config.mode else "HumanoidOffset"
	if mode == "Noop" then
		return NoopDriver.new()
	end
	if mode == "ShakeBus" then
		local bus = ShakeBusDriver.new()
		if config and config.onShakeOffset then
			bus:setListener(config.onShakeOffset)
		end
		return bus
	end
	return HumanoidOffsetDriver.new()
end

Camera.HumanoidOffsetDriver = HumanoidOffsetDriver
Camera.ShakeBusDriver = ShakeBusDriver
Camera.NoopDriver = NoopDriver

return Camera
