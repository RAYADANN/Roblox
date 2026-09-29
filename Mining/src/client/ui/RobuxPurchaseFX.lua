--!strict
-- Полноэкранный «вау»-эффект успешной покупки за Robux.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = require(script.Parent.Parent.core.SoundManager)
local CameraShake = require(script.Parent.Parent.core.CameraShake)
local Haptics = require(script.Parent.Parent.core.Haptics)
local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local UiScreen = require(script.Parent.util.UiScreen)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

export type PlayOptions = {
	shopKey: string?,
	productName: string?,
	tier: ("shop" | "egg" | "gamepass")?,
}

local RobuxPurchaseFX = {}

local FX_GUI_NAME = "DeepDigger_RobuxPurchaseFX"
local DEDUP_SEC = 0.85
local ROBUX_GREEN = Color3.fromRGB(88, 220, 140)
local GOLD = Color3.fromRGB(255, 210, 70)

local lastPlayAt = 0

local function ensureGui(): ScreenGui?
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	return UiScreen.ensure(pg, FX_GUI_NAME, "fx")
end

local function viewportSize(): Vector2
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1280, 720)
end

local function spawnFlash(gui: ScreenGui)
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0.82
	flash.BorderSizePixel = 0
	flash.ZIndex = 300
	flash.Parent = gui
	TweenService:Create(flash, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	Debris:AddItem(flash, 0.6)
end

local function spawnShockwave(gui: ScreenGui, color: Color3, delaySec: number, size: number)
	task.delay(delaySec, function()
		if not gui.Parent then
			return
		end
		local ring = Instance.new("Frame")
		ring.Size = UDim2.fromOffset(24, 24)
		ring.Position = UDim2.fromScale(0.5, 0.42)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.ZIndex = 305
		ring.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 5
		stroke.Transparency = 0.05
		stroke.Parent = ring
		local dur = 0.65
		TweenService:Create(ring, TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(size, size),
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Thickness = 1,
		}):Play()
		Debris:AddItem(ring, dur + 0.1)
	end)
end

local function spawnRobuxRain(gui: ScreenGui, count: number)
	local vp = viewportSize()
	for i = 1, count do
		task.delay((i - 1) * 0.018, function()
			if not gui.Parent then
				return
			end
			local size = 26 + math.random() * 16
			local icon = Instance.new("ImageLabel")
			icon.BackgroundTransparency = 1
			icon.Image = UiAssets.robux()
			icon.Size = UDim2.fromOffset(size, size)
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromOffset(math.random() * vp.X, -size)
			icon.Rotation = math.random(-25, 25)
			icon.ZIndex = 302
			icon.Parent = gui
			local endY = vp.Y + size + 40
			local endX = icon.Position.X.Offset + (math.random() - 0.5) * 80
			local dur = 1.0 + math.random() * 0.45
			TweenService:Create(icon, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(endX, endY),
				Rotation = icon.Rotation + (math.random() - 0.5) * 180,
				ImageTransparency = 0.35,
			}):Play()
			Debris:AddItem(icon, dur + 0.1)
		end)
	end
end

local function spawnBanner(gui: ScreenGui, title: string, subtitle: string?)
	local panel = Instance.new("Frame")
	panel.Name = "Banner"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.38)
	panel.Size = UDim2.fromOffset(0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.XY
	panel.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.ZIndex = 310
	panel.Parent = gui

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 18)
	pad.PaddingBottom = UDim.new(0, 18)
	pad.PaddingLeft = UDim.new(0, 28)
	pad.PaddingRight = UDim.new(0, 28)
	pad.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = ROBUX_GREEN
	stroke.Thickness = 2.5
	stroke.Transparency = 0.15
	stroke.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local rbx = Instance.new("ImageLabel")
	rbx.LayoutOrder = 0
	rbx.Size = UDim2.fromOffset(52, 52)
	rbx.BackgroundTransparency = 1
	rbx.Image = UiAssets.robux()
	rbx.ScaleType = Enum.ScaleType.Fit
	rbx.ZIndex = 311
	rbx.Parent = panel

	local textCol = Instance.new("Frame")
	textCol.LayoutOrder = 1
	textCol.AutomaticSize = Enum.AutomaticSize.XY
	textCol.BackgroundTransparency = 1
	textCol.Parent = panel

	local textLayout = Instance.new("UIListLayout")
	textLayout.FillDirection = Enum.FillDirection.Vertical
	textLayout.Padding = UDim.new(0, 4)
	textLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textLayout.Parent = textCol

	local titleLabel = Instance.new("TextLabel")
	titleLabel.LayoutOrder = 0
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 28
	titleLabel.TextColor3 = GOLD
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.AutomaticSize = Enum.AutomaticSize.XY
	titleLabel.ZIndex = 311
	titleLabel.Parent = textCol

	if subtitle and subtitle ~= "" then
		local sub = Instance.new("TextLabel")
		sub.LayoutOrder = 1
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.GothamBold
		sub.TextSize = 16
		sub.TextColor3 = ROBUX_GREEN
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Text = subtitle
		sub.AutomaticSize = Enum.AutomaticSize.XY
		sub.ZIndex = 311
		sub.Parent = textCol
	end

	panel.Size = UDim2.fromScale(0, 0)
	panel.BackgroundTransparency = 1
	stroke.Transparency = 1
	titleLabel.TextTransparency = 1
	rbx.ImageTransparency = 1
	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.08,
	}):Play()
	TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 0.15,
	}):Play()
	TweenService:Create(titleLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(rbx, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ImageTransparency = 0,
	}):Play()

	task.delay(1.35, function()
		if not panel.Parent then
			return
		end
		TweenService:Create(panel, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, 0.28),
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(titleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1,
		}):Play()
		Debris:AddItem(panel, 0.35)
	end)
end

function RobuxPurchaseFX.play(opts: PlayOptions?): ()
	local ok, err = pcall(function()
		local now = os.clock()
		if now - lastPlayAt < DEDUP_SEC then
			return
		end
		lastPlayAt = now

		local gui = ensureGui()
		if not gui then
			return
		end

		local tier = if opts and opts.tier then opts.tier else "shop"
		local title = if tier == "egg"
			then L("fx.robux.titleEgg")
			elseif tier == "gamepass"
			then L("fx.robux.titleGamepass")
			else L("fx.robux.titleShop")

		local subtitle = if opts and typeof(opts.productName) == "string" and opts.productName ~= ""
			then opts.productName
			else nil

		spawnFlash(gui)
		spawnShockwave(gui, ROBUX_GREEN, 0.05, 280)
		spawnShockwave(gui, GOLD, 0.12, 360)
		spawnRobuxRain(gui, if tier == "egg" then 72 else 54)
		spawnBanner(gui, title, subtitle)

		SoundManager.playWithPitch("shop_purchase", 1.08)
		task.delay(0.12, function()
			SoundManager.playWithPitch("buy_upgrade", 1.15)
		end)
		pcall(function()
			CameraShake.shake(0.35, 0.35)
		end)
		pcall(function()
			Haptics.pulse("crit")
		end)
	end)
	if not ok then
		warn("[RobuxPurchaseFX]", err)
	end
end

return RobuxPurchaseFX
