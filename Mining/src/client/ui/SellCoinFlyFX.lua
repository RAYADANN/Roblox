--!strict
-- Монеты летят от центра экрана к CoinChip при успешной продаже.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local UiScreen = require(script.Parent.util.UiScreen)
local ViewportLayout = require(script.Parent.util.ViewportLayout)
local ResourceChip = require(script.Parent.hud.components.ResourceChip)
local SoundManager = require(script.Parent.Parent.core.SoundManager)

local SellCoinFlyFX = {}

local GUI_NAME = "DeepDigger_SellCoinFly"
local MAX_COINS = 20
local MIN_COINS = 8

export type Options = {
	amount: number,
	sourceScreenPos: Vector2?,
	targetScreenPos: Vector2?,
}

local function defaultSource(viewport: Vector2): Vector2
	return Vector2.new(viewport.X * 0.5, viewport.Y * 0.78)
end

local function defaultTarget(): Vector2
	local center = ResourceChip.getCoinScreenCenter()
	if center then
		return center
	end
	return Vector2.new(ViewportLayout.sidePad() + 60, ViewportLayout.topHudY() + 24)
end

local function sellPitch(amount: number): number
	local logTerm = math.log10(math.max(amount, 1) / 100)
	return math.clamp(1.0 + logTerm * 0.15, 1.0, 1.45)
end

local function coinCount(amount: number): number
	return math.clamp(math.floor(amount / 50), MIN_COINS, MAX_COINS)
end

local function ensureGui(): ScreenGui?
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	return UiScreen.ensure(pg, GUI_NAME, "fx")
end

function SellCoinFlyFX.play(opts: Options): ()
	local ok, err = pcall(function()
		if opts.amount <= 0 then
			return
		end
		local gui = ensureGui()
		if not gui then
			return
		end

		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1024, 768)
		local source = opts.sourceScreenPos or defaultSource(viewport)
		local target = opts.targetScreenPos or defaultTarget()

		SoundManager.playWithPitch("sell_success", sellPitch(opts.amount))

		local count = coinCount(opts.amount)
		for i = 1, count do
			task.delay((i - 1) * 0.02, function()
				if not gui.Parent then
					return
				end
				local size = 22 + math.random() * 10
				local label = Instance.new("ImageLabel")
				label.Size = UDim2.fromOffset(size, size)
				label.AnchorPoint = Vector2.new(0.5, 0.5)
				label.Position = UDim2.fromOffset(
					source.X + (math.random() - 0.5) * 40,
					source.Y + (math.random() - 0.5) * 24
				)
				label.BackgroundTransparency = 1
				label.Image = UiAssets.coin()
				label.ScaleType = Enum.ScaleType.Fit
				label.ZIndex = 10
				label.Parent = gui

				local mid = (source + target) * 0.5 + Vector2.new((math.random() - 0.5) * 80, -50 - math.random() * 30)
				local duration = 0.55 + math.random() * 0.25
				local elapsed = 0
				local conn: RBXScriptConnection? = nil
				conn = RunService.RenderStepped:Connect(function(dt)
					elapsed += dt
					local t = math.clamp(elapsed / duration, 0, 1)
					local u = 1 - t
					local pos = u * u * source + 2 * u * t * mid + t * t * target
					label.Position = UDim2.fromOffset(pos.X, pos.Y)
					if t >= 0.8 then
						label.ImageTransparency = (t - 0.8) / 0.2
					end
					if t >= 1 then
						if conn then
							conn:Disconnect()
						end
						label:Destroy()
					end
				end)
				Debris:AddItem(label, duration + 0.3)
			end)
		end
	end)
	if not ok then
		warn("[SellCoinFlyFX]", err)
	end
end

return SellCoinFlyFX
