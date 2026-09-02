--!strict
-- Клиент: вертикальные монеты — вращение вокруг Y + bob вверх/вниз.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)

local COIN_TAG = "Coin"

local CoinSpinner = {}

local _conn: RBXScriptConnection? = nil

function CoinSpinner.start()
	if _conn then
		return
	end

	local rotSpeed = math.rad(Constants.COIN_ROTATE_SPEED)
	local bobAmp = Constants.COIN_BOB_AMPLITUDE
	local bobOmega = Constants.COIN_BOB_SPEED * math.pi * 2

	_conn = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, inst in CollectionService:GetTagged(COIN_TAG) do
			if inst:IsA("BasePart") and inst.Parent then
				local homeY = inst:GetAttribute("HomeY")
				if typeof(homeY) ~= "number" then
					homeY = inst.Position.Y
				end
				local phase = inst:GetAttribute("BobPhase")
				if typeof(phase) ~= "number" then
					phase = 0
				end
				local bob = math.sin(t * bobOmega + phase) * bobAmp
				local yaw = t * rotSpeed + phase
				local p = inst.Position
				inst.CFrame = CFrame.new(p.X, homeY + bob, p.Z) * CFrame.Angles(0, yaw, 0)
			end
		end
	end)
end

return CoinSpinner
