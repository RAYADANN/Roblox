--!strict
-- Частицы и всплывающий уровень при успешной покупке апгрейда.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = require(script.Parent.Parent.core.SoundManager)
local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local UiScreen = require(script.Parent.util.UiScreen)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local UpgradeFanfareFX = {}

local GUI_NAME = "DeepDigger_UpgradeFanfare"
local SPARKLE_COUNT = 10

export type Options = {
	anchor: GuiObject,
	accent: Color3,
	newLevel: number,
	upgradeId: string?,
}

local function ensureGui(): ScreenGui?
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	return UiScreen.ensure(pg, GUI_NAME, "fx")
end

local function absCenter(gui: GuiObject): Vector2
	local pos = gui.AbsolutePosition
	local size = gui.AbsoluteSize
	return pos + size * 0.5
end

local function spawnSparkle(gui: ScreenGui, origin: Vector2, accent: Color3, delaySec: number)
	task.delay(delaySec, function()
		if not gui.Parent then
			return
		end
		local size = 14 + math.random() * 10
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = UiAssets.image("icon_sparkle")
		img.ImageColor3 = accent
		img.Size = UDim2.fromOffset(size, size)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.fromOffset(origin.X + math.random(-20, 20), origin.Y + math.random(-12, 12))
		img.ZIndex = 200
		img.Parent = gui

		local angle = math.random() * math.pi * 2
		local dist = 40 + math.random() * 50
		local target = origin + Vector2.new(math.cos(angle) * dist, math.sin(angle) * dist - 30)

		TweenService:Create(img, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(target.X, target.Y),
			ImageTransparency = 1,
			Rotation = math.random(-90, 90),
		}):Play()
		Debris:AddItem(img, 0.6)
	end)
end

local function spawnLevelPop(gui: ScreenGui, origin: Vector2, accent: Color3, newLevel: number, upgradeId: string?)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 22
	label.TextColor3 = accent
	label.TextStrokeTransparency = 0.5
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromOffset(origin.X, origin.Y - 8)
	label.Size = UDim2.fromOffset(120, 32)
	label.ZIndex = 201
	if upgradeId == "autoSell" then
		label.Text = L("component.upg.purchased")
	else
		label.Text = L("component.upg.levelShort", { level = newLevel })
	end
	label.Parent = gui

	TweenService:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(origin.X, origin.Y - 48),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 0.75)
end

function UpgradeFanfareFX.play(opts: Options): ()
	local ok, err = pcall(function()
		local gui = ensureGui()
		if not gui or not opts.anchor or opts.anchor.AbsoluteSize.X <= 0 then
			return
		end

		SoundManager.playWithPitch("buy_upgrade", 1.18)

		local center = absCenter(opts.anchor)
		for i = 1, SPARKLE_COUNT do
			spawnSparkle(gui, center, opts.accent, (i - 1) * 0.025)
		end
		spawnLevelPop(gui, center, opts.accent, opts.newLevel, opts.upgradeId)

		local stroke = opts.anchor:FindFirstChildOfClass("UIStroke")
		if stroke then
			local orig = stroke.Thickness
			stroke.Thickness = orig + 2
			task.delay(0.15, function()
				if stroke.Parent then
					stroke.Thickness = orig
				end
			end)
		end
	end)
	if not ok then
		warn("[UpgradeFanfareFX]", err)
	end
end

return UpgradeFanfareFX
