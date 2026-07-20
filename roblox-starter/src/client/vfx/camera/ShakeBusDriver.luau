--!strict
-- ShakeBus: VFX только публикует offset. Твой camera-controller читает getOffset().
-- Нужен когда камера Scriptable / spectate / vehicle / cutscene.

local RunService = game:GetService("RunService")

local CameraTypes = require(script.Parent.Types)

export type CameraDriver = CameraTypes.CameraDriver

export type ShakeBusDriver = CameraDriver & {
	getOffset: (self: ShakeBusDriver) -> Vector3,
	--- Опционально: движок сам пушит offset в колбэк каждый кадр.
	setListener: (self: ShakeBusDriver, listener: ((Vector3) -> ())?) -> (),
}

local ShakeBusDriver = {}
ShakeBusDriver.__index = ShakeBusDriver

function ShakeBusDriver.new(): ShakeBusDriver
	local self = setmetatable({
		_offset = Vector3.zero,
		_listener = nil :: ((Vector3) -> ())?,
		_shakeConn = nil :: RBXScriptConnection?,
		_rumbleAmp = 0,
		_rumbleRough = 18,
		_rumbleConn = nil :: RBXScriptConnection?,
		_destroyed = false,
	}, ShakeBusDriver)
	return (self :: any) :: ShakeBusDriver
end

function ShakeBusDriver:isSupported(): boolean
	return true
end

function ShakeBusDriver:getOffset(): Vector3
	return self._offset
end

function ShakeBusDriver:setListener(listener: ((Vector3) -> ())?)
	self._listener = listener
end

local function publish(self: any, offset: Vector3)
	self._offset = offset
	if self._listener then
		self._listener(offset)
	end
end

function ShakeBusDriver:shake(amplitude: number, duration: number, roughness: number?)
	if self._destroyed or amplitude <= 0 or duration <= 0 then
		return
	end
	if self._shakeConn then
		self._shakeConn:Disconnect()
		self._shakeConn = nil
	end
	local rough = roughness or 28
	local elapsed = 0
	self._shakeConn = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		local t = math.clamp(elapsed / duration, 0, 1)
		local a = amplitude * (1 - t)
		local ox = math.noise(elapsed * rough, 1.1) * 2 * a
		local oy = math.noise(elapsed * rough * 1.17, 4.2) * 2 * a
		local oz = math.noise(elapsed * rough * 0.9, 7.7) * a * 0.35
		if self._rumbleAmp > 0 then
			local r = self._rumbleAmp
			ox += math.noise(elapsed * self._rumbleRough, 9.0) * 2 * r
			oy += math.noise(elapsed * self._rumbleRough * 1.3, 2.4) * 2 * r
		end
		publish(self, Vector3.new(ox, oy, oz))
		if t >= 1 then
			if self._rumbleAmp <= 0 then
				publish(self, Vector3.zero)
			end
			if self._shakeConn then
				self._shakeConn:Disconnect()
				self._shakeConn = nil
			end
		end
	end)
end

function ShakeBusDriver:setRumble(amplitude: number, roughness: number?)
	self._rumbleAmp = math.max(0, amplitude)
	self._rumbleRough = roughness or 18
	if self._rumbleAmp <= 0 then
		if self._rumbleConn then
			self._rumbleConn:Disconnect()
			self._rumbleConn = nil
		end
		if not self._shakeConn then
			publish(self, Vector3.zero)
		end
		return
	end
	if self._rumbleConn then
		return
	end
	local t0 = os.clock()
	self._rumbleConn = RunService.RenderStepped:Connect(function()
		if self._shakeConn then
			return
		end
		local elapsed = os.clock() - t0
		local a = self._rumbleAmp
		local ox = math.noise(elapsed * self._rumbleRough, 9.0) * 2 * a
		local oy = math.noise(elapsed * self._rumbleRough * 1.3, 2.4) * 2 * a
		publish(self, Vector3.new(ox, oy, 0))
	end)
end

function ShakeBusDriver:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:setRumble(0)
	if self._shakeConn then
		self._shakeConn:Disconnect()
		self._shakeConn = nil
	end
	publish(self, Vector3.zero)
	self._listener = nil
end

return ShakeBusDriver
