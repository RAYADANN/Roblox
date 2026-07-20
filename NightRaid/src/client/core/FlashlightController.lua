--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local Remotes = require(shared.net.Remotes)
local CombatConfig = require(shared.data.CombatConfig)

export type FlashlightController = {
	isShining: (self: FlashlightController) -> boolean,
	destroy: (self: FlashlightController) -> (),
}

local FlashlightController = {}
FlashlightController.__index = FlashlightController

local function isShineInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton2
		or input.KeyCode == Enum.KeyCode.F
		or input.UserInputType == Enum.UserInputType.Touch
end

function FlashlightController.new(): FlashlightController
	local self = setmetatable({
		_player = Players.LocalPlayer,
		_shining = false,
		_battery = 1,
		_phase = "Day",
		_beam = nil :: Beam?,
		_attachment0 = nil :: Attachment?,
		_attachment1 = nil :: Attachment?,
		_conns = {} :: { RBXScriptConnection },
	}, FlashlightController)

	table.insert(
		self._conns,
		self._player.CharacterAdded:Connect(function(character)
			self:_onCharacter(character)
		end)
	)
	if self._player.Character then
		self:_onCharacter(self._player.Character)
	end

	table.insert(
		self._conns,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if isShineInput(input) then
				self:_setShining(true)
			end
		end)
	)

	table.insert(
		self._conns,
		UserInputService.InputEnded:Connect(function(input)
			if isShineInput(input) then
				self:_setShining(false)
			end
		end)
	)

	table.insert(
		self._conns,
		Remotes.CycleChanged.OnClientEvent:Connect(function(phase: string)
			self._phase = phase
			if phase == "Dusk" then
				self._battery = 1
				self._player:SetAttribute("Battery", self._battery)
			end
		end)
	)

	table.insert(
		self._conns,
		RunService.RenderStepped:Connect(function(dt)
			self:_stepBattery(dt)
		end)
	)

	self._player:SetAttribute("Battery", self._battery)
	return self
end

function FlashlightController:_ensureBeam(character: Model)
	local head = character:WaitForChild("Head") :: BasePart
	if self._attachment0 then
		self._attachment0:Destroy()
	end
	if self._attachment1 then
		self._attachment1:Destroy()
	end
	if self._beam then
		self._beam:Destroy()
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "FlashAttach0"
	a0.Parent = head

	local a1 = Instance.new("Attachment")
	a1.Name = "FlashAttach1"
	a1.Position = Vector3.new(0, 0, -CombatConfig.Light.range)
	a1.Parent = head

	local beam = Instance.new("Beam")
	beam.Name = "FlashBeam"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.2
	beam.Width1 = 6
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 245, 180))
	beam.Transparency = NumberSequence.new(0.25)
	beam.FaceCamera = true
	beam.Enabled = false
	beam.Parent = head

	self._attachment0 = a0
	self._attachment1 = a1
	self._beam = beam
end

function FlashlightController:_setShining(value: boolean)
	if self._shining == value then
		return
	end
	if value and self._battery <= 0 then
		return
	end
	self._shining = value
	if self._beam then
		self._beam.Enabled = self._shining
	end
	Remotes.ShineState:FireServer(self._shining)
end

function FlashlightController:_onCharacter(character: Model)
	self:_ensureBeam(character)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	table.insert(
		self._conns,
		humanoid.Died:Connect(function()
			self:_setShining(false)
		end)
	)
end

function FlashlightController:_stepBattery(dt: number)
	local light = CombatConfig.Light
	if self._shining then
		self._battery = math.max(0, self._battery - light.batteryDrainPerSec * dt)
		if self._battery <= 0 then
			self:_setShining(false)
		end
	else
		local rate = if self._phase == "Day"
			then light.batteryRechargeDayPerSec
			else light.batteryRechargeOtherPerSec
		self._battery = math.min(1, self._battery + rate * dt)
	end
	self._player:SetAttribute("Battery", self._battery)
end

function FlashlightController:isShining(): boolean
	return self._shining
end

function FlashlightController:destroy()
	self:_setShining(false)
	for _, conn in self._conns do
		conn:Disconnect()
	end
	table.clear(self._conns)
	if self._beam then
		self._beam:Destroy()
	end
	if self._attachment0 then
		self._attachment0:Destroy()
	end
	if self._attachment1 then
		self._attachment1:Destroy()
	end
end

return FlashlightController
