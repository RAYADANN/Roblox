--!strict
-- Баннер «игрок вылупил legendary+» для остальных клиентов.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = require(script.Parent.Parent.core.SoundManager)
local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local UiScreen = require(script.Parent.util.UiScreen)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

export type Payload = {
	userId: number,
	playerName: string,
	petId: string,
	petName: string,
	rarity: string,
}

local HatchBroadcastFX = {}

local FX_GUI_NAME = "DeepDigger_HatchBroadcastFX"

local RARITY_COLOR: { [string]: Color3 } = {
	legendary = Color3.fromRGB(255, 180, 30),
	mythic = Color3.fromRGB(255, 70, 70),
}

local function ensureGui(): ScreenGui?
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	return UiScreen.ensure(pg, FX_GUI_NAME, "fx")
end

function HatchBroadcastFX.play(payload: Payload): ()
	local ok, err = pcall(function()
		local lp = Players.LocalPlayer
		if not lp or payload.userId == lp.UserId then
			return
		end
		if payload.rarity ~= "legendary" and payload.rarity ~= "mythic" then
			return
		end

		local gui = ensureGui()
		if not gui then
			return
		end

		local accent = RARITY_COLOR[payload.rarity] or RARITY_COLOR.legendary
		local petName = L(payload.petName)

		local banner = Instance.new("Frame")
		banner.Name = "HatchBroadcast"
		banner.AnchorPoint = Vector2.new(0.5, 0)
		banner.Position = UDim2.new(0.5, 0, 0, 72)
		banner.Size = UDim2.fromOffset(420, 56)
		banner.BackgroundColor3 = Color3.fromRGB(16, 18, 32)
		banner.BackgroundTransparency = 0.1
		banner.BorderSizePixel = 0
		banner.ZIndex = 280
		banner.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = banner

		local stroke = Instance.new("UIStroke")
		stroke.Color = accent
		stroke.Thickness = 2
		stroke.Transparency = 0.2
		stroke.Parent = banner

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromOffset(36, 36)
		icon.Position = UDim2.new(0, 10, 0.5, -18)
		icon.BackgroundTransparency = 1
		icon.Image = UiAssets.image("icon_egg")
		icon.ImageColor3 = accent
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 281
		icon.Parent = banner

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -58, 1, -8)
		label.Position = UDim2.new(0, 52, 0, 4)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextSize = 15
		label.TextColor3 = accent
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextWrapped = true
		label.Text = L("fx.hatchBroadcast.banner", {
			player = payload.playerName,
			pet = petName,
			rarity = payload.rarity:upper(),
		})
		label.ZIndex = 281
		label.Parent = banner

		banner.Position = UDim2.new(0.5, 0, 0, 40)
		banner.BackgroundTransparency = 1
		label.TextTransparency = 1
		icon.ImageTransparency = 1
		TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 72),
			BackgroundTransparency = 0.1,
		}):Play()
		TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		}):Play()
		TweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0,
		}):Play()

		if payload.rarity == "mythic" then
			SoundManager.play("hatch_mythic")
		else
			SoundManager.playWithPitch("hatch_legendary", 0.95)
		end

		task.delay(3.2, function()
			if not banner.Parent then
				return
			end
			TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, 48),
				BackgroundTransparency = 1,
			}):Play()
			TweenService:Create(label, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1,
			}):Play()
			Debris:AddItem(banner, 0.35)
		end)
	end)
	if not ok then
		warn("[HatchBroadcastFX]", err)
	end
end

return HatchBroadcastFX
