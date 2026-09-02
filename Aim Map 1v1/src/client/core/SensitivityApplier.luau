--!strict
-- Applies profile lookSensitivity to custom LookController (not Roblox MouseDeltaSensitivity —
-- that property is unreliable with current CameraModule / IAS).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LookController = require(script.Parent.LookController)
local SensitivityLogic = require(ReplicatedStorage.shared.util.SensitivityLogic)

local SensitivityApplier = {}

function SensitivityApplier.apply(value: number)
    LookController.setSensitivity(SensitivityLogic.clamp(value))
end

return SensitivityApplier
