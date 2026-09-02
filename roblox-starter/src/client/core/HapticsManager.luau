--!strict
-- Короткие haptic pulses. Уважает Settings + reduceMotion.

local HapticService = game:GetService("HapticService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HapticLogic = require(ReplicatedStorage.shared.vfx.HapticLogic)
local SettingsManager = require(script.Parent.SettingsManager)

local HapticsManager = {}

local function pickInput(): Enum.UserInputType?
	if UserInputService.TouchEnabled then
		return Enum.UserInputType.Gamepad1
	end
	if UserInputService.GamepadEnabled then
		return Enum.UserInputType.Gamepad1
	end
	return nil
end

function HapticsManager.pulse(strength: number, duration: number?)
	if not HapticLogic.allows(SettingsManager.isHapticsEnabled(), SettingsManager.isReduceMotion()) then
		return
	end
	local input = pickInput()
	if not input then
		return
	end
	local s = math.clamp(strength, 0, 1)
	if s <= 0 then
		return
	end
	local dur = duration or 0.08
	pcall(function()
		if not HapticService:IsMotorSupported(input, Enum.VibrationMotor.Large) then
			return
		end
		HapticService:SetMotor(input, Enum.VibrationMotor.Large, s)
		task.delay(dur, function()
			pcall(function()
				HapticService:SetMotor(input, Enum.VibrationMotor.Large, 0)
			end)
		end)
	end)
end

function HapticsManager.pulseProfile(profile: string?, intensity: number?)
	local s = HapticLogic.profileStrength(profile) * (intensity or 1)
	local dur = if profile == "Heavy" then 0.14 elseif profile == "Light" then 0.05 else 0.09
	HapticsManager.pulse(s, dur)
end

return HapticsManager
