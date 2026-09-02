--!strict
-- Монетка летит из мира в чип очков (HUD).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ImageIds = require(script.Parent.Parent.ui.ImageIds)
local UiScreen = require(script.Parent.Parent.ui.util.UiScreen)
local Zap = require(script.Parent.Parent.net.NetClient)

local CoinFlyFx = {}

local function getFxLayer(): Frame
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = UiScreen.ensure(playerGui, "CoinFlyFx", "fx")
	local layer = gui:FindFirstChild("Layer")
	if layer and layer:IsA("Frame") then
		return layer
	end
	local frame = Instance.new("Frame")
	frame.Name = "Layer"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	return frame
end

local function hudTarget(): Vector2
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local chip = playerGui:FindFirstChild("PointsChip", true)
		if chip and chip:IsA("GuiObject") then
			local abs = chip.AbsolutePosition
			local size = chip.AbsoluteSize
			return abs + size / 2
		end
	end
	local cam = Workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	return Vector2.new(vp.X * 0.5, 52)
end

local function fly(worldPos: Vector3, isRed: boolean)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end

	local screen, onScreen = cam:WorldToViewportPoint(worldPos)
	local start = Vector2.new(screen.X, screen.Y)
	if not onScreen or screen.Z < 0 then
		start = hudTarget() + Vector2.new(0, 120)
	end

	local target = hudTarget()
	local layer = getFxLayer()

	local coin = Instance.new("ImageLabel")
	coin.Name = "FlyCoin"
	coin.AnchorPoint = Vector2.new(0.5, 0.5)
	coin.Size = UDim2.fromOffset(44, 44)
	coin.Position = UDim2.fromOffset(start.X, start.Y)
	coin.BackgroundTransparency = 1
	coin.Image = ImageIds.Hud.coins
	coin.ImageColor3 = if isRed then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(255, 220, 40)
	coin.ScaleType = Enum.ScaleType.Fit
	coin.ZIndex = 10
	coin.Parent = layer

	local mid = Vector2.new((start.X + target.X) / 2, math.min(start.Y, target.Y) - 80)
	local t1 = TweenService:Create(
		coin,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(mid.X, mid.Y), Size = UDim2.fromOffset(52, 52) }
	)
	local t2 = TweenService:Create(
		coin,
		TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{ Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(22, 22) }
	)

	t1:Play()
	t1.Completed:Connect(function()
		t2:Play()
	end)
	t2.Completed:Connect(function()
		coin:Destroy()
	end)
end

function CoinFlyFx.start()
	Zap.CoinCollected.On(function(payload)
		fly(Vector3.new(payload.x, payload.y, payload.z), payload.isRed)
	end)
end

return CoinFlyFx
