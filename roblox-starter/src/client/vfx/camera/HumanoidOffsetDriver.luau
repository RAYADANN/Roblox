--!strict
-- Shake через Humanoid.CameraOffset. Для default Roblox camera / персонажа.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraTypes = require(script.Parent.Types)

export type CameraDriver = CameraTypes.CameraDriver

local HumanoidOffsetDriver = {}
HumanoidOffsetDriver.__index = HumanoidOffsetDriver

local function getHumanoid(): Humanoid?
	local player = Players.LocalPlayer
	local character = player and player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function HumanoidOffsetDriver.new(): CameraDriver
	local self = setmetatable({
		_shakeConn = nil :: RBXScriptConnection?,
		_rumbleConn = nil :: RBXScriptConnection?,
		_rumbleAmp = 0,
		_rumbleRough = 18,
		_destroyed = false,
	}, HumanoidOffsetDriver)
	return (self :: any) :: CameraDriver
end

function HumanoidOffsetDriver:isSupported(): boolean
	return getHumanoid() ~= nil
end

function HumanoidOffsetDriver:shake(amplitude: number, duration: number, roughness: number?)
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
		local hum = getHumanoid()
		if not hum then
			if self._shakeConn then
				self._shakeConn:Disconnect()
				self._shakeConn = nil
			end
			return
		end
		local t = math.clamp(elapsed / duration, 0, 1)
		local a = amplitude * (1 - t)
		local ox = math.noise(elapsed * rough, 1.1) * 2 * a
		local oy = math.noise(elapsed * rough * 1.17, 4.2) * 2 * a
		-- rumble складывается, если активен
		local r = self._rumbleAmp
		if r > 0 then
			ox += math.noise(elapsed * self._rumbleRough, 9.0) * 2 * r
			oy += math.noise(elapsed * self._rumbleRough * 1.3, 2.4) * 2 * r
		end
		hum.CameraOffset = Vector3.new(ox, oy, 0)
		if t >= 1 then
			if self._rumbleAmp <= 0 then
				hum.CameraOffset = Vector3.zero
			end
			if self._shakeConn then
				self._shakeConn:Disconnect()
				self._shakeConn = nil
			end
		end
	end)
end

function HumanoidOffsetDriver:setRumble(amplitude: number, roughness: number?)
	self._rumbleAmp = math.max(0, amplitude)
	self._rumbleRough = roughness or 18
	if self._rumbleAmp <= 0 then
		if self._rumbleConn then
			self._rumbleConn:Disconnect()
			self._rumbleConn = nil
		end
		local hum = getHumanoid()
		if hum and not self._shakeConn then
			hum.CameraOffset = Vector3.zero
		end
		return
	end
	if self._rumbleConn then
		return
	end
	local t0 = os.clock()
	self._rumbleConn = RunService.RenderStepped:Connect(function()
		if self._shakeConn then
			return -- shake кадр уже пишет offset
		end
		local hum = getHumanoid()
		if not hum then
			return
		end
		local elapsed = os.clock() - t0
		local a = self._rumbleAmp
		local ox = math.noise(elapsed * self._rumbleRough, 9.0) * 2 * a
		local oy = math.noise(elapsed * self._rumbleRough * 1.3, 2.4) * 2 * a
		hum.CameraOffset = Vector3.new(ox, oy, 0)
	end)
end

function HumanoidOffsetDriver:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:setRumble(0)
	if self._shakeConn then
		self._shakeConn:Disconnect()
		self._shakeConn = nil
	end
	local hum = getHumanoid()
	if hum then
		hum.CameraOffset = Vector3.zero
	end
end

return HumanoidOffsetDriver
