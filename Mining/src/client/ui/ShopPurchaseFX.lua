--!strict
-- ShopPurchaseFX — звук + визуальный фидбек успешной покупки в магазине.
-- Вызывается после server Notify (kind = "shop_purchase") и при закрытии
-- Roblox purchase prompt (ShopPurchase.lua). Sparkles рисуются в FX-overlay,
-- чтобы ScrollingFrame магазина не обрезал анимацию (ClipsDescendants).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = require(script.Parent.Parent.core.SoundManager)
local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local UiMotion = require(script.Parent.util.UiMotion)
local UiScreen = require(script.Parent.util.UiScreen)
local ViewportLayout = require(script.Parent.util.ViewportLayout)
local theme = require(script.Parent.hud.theme)

export type PlayOptions = {
	shopKey: string?,
	accent: Color3?,
}

local CARD_PREFIXES = { "ShopCard_", "Featured_", "Boost_" }
local FX_GUI_NAME = "DeepDigger_ShopPurchaseFX"
local C = theme.C
local CARD_LOOKUP_RETRIES = 8
local CARD_LOOKUP_DELAY = 0.05
local SOUND_DEDUP_SEC = 0.45

local ShopPurchaseFX = {}
local lastSoundAt: { [string]: number } = {}

local function ensureFxGui(): ScreenGui?
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	return UiScreen.ensure(pg, FX_GUI_NAME, "fx")
end

local function findShopCard(shopKey: string): GuiObject?
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	for _, prefix in CARD_PREFIXES do
		local name = prefix .. shopKey
		local card = pg:FindFirstChild(name, true)
		if card and card:IsA("GuiObject") then
			return card
		end
	end
	return nil
end

local function viewportSize(): Vector2
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1280, 720)
end

local function isOnScreen(centerX: number, centerY: number): boolean
	local vp = viewportSize()
	local margin = 24
	return centerX >= -margin
		and centerX <= vp.X + margin
		and centerY >= -margin
		and centerY <= vp.Y + margin
end

local function fallbackBurstCenter(): (number, number)
	local player = Players.LocalPlayer
	if player then
		local pg = player:FindFirstChildOfClass("PlayerGui")
		local hud = if pg then pg:FindFirstChild("DeepDiggerHUD") else nil
		local mainPanel = if hud then hud:FindFirstChild("MainPanel") else nil
		local modal = if mainPanel then mainPanel:FindFirstChild("Modal") else nil
		if modal and modal:IsA("GuiObject") then
			local pos = modal.AbsolutePosition
			local size = modal.AbsoluteSize
			if size.X > 0 and size.Y > 0 then
				return pos.X + size.X * 0.5, pos.Y + size.Y * 0.45
			end
		end
	end
	local vp = viewportSize()
	return vp.X * 0.5, vp.Y * 0.45
end

local function cardCenter(card: GuiObject): (number?, number?)
	if not card.Parent then
		return nil
	end
	local pos = card.AbsolutePosition
	local size = card.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return nil
	end
	local centerX = pos.X + size.X * 0.5
	local centerY = pos.Y + size.Y * 0.5
	if not isOnScreen(centerX, centerY) then
		return nil
	end
	return centerX, centerY
end

local function flashStroke(card: GuiObject, accent: Color3)
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if not stroke then
		return
	end
	local origColor = stroke.Color
	local origT = stroke.Transparency
	stroke.Color = accent
	TweenService:Create(
		stroke,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 0 }
	):Play()
	task.delay(0.32, function()
		if not stroke.Parent then
			return
		end
		TweenService:Create(
			stroke,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Color = origColor, Transparency = origT }
		):Play()
	end)
end

local function spawnBurstAt(centerX: number, centerY: number, accent: Color3, zIndex: number)
	local gui = ensureFxGui()
	if not gui then
		return
	end
	local px = ViewportLayout.px
	local sparkleSize = px(14)
	local checkSize = px(28)

	for i = 1, 5 do
		local star = Instance.new("ImageLabel")
		star.Name = "PurchaseSparkle"
		star.Size = UDim2.fromOffset(sparkleSize, sparkleSize)
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Position = UDim2.fromOffset(centerX, centerY)
		star.BackgroundTransparency = 1
		star.Image = UiAssets.image("icon_sparkle")
		star.ImageColor3 = accent
		star.ImageTransparency = 0.1
		star.ScaleType = Enum.ScaleType.Fit
		star.ZIndex = zIndex
		star.Parent = gui

		local angle = (i - 1) * (math.pi * 2 / 5) + math.random() * 0.4
		local dist = px(22 + math.random() * 10)
		local endPos = UDim2.fromOffset(centerX + math.cos(angle) * dist, centerY + math.sin(angle) * dist)
		local dur = 0.38 + math.random() * 0.08
		TweenService:Create(star, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = endPos,
			ImageTransparency = 1,
			Rotation = star.Rotation + 90,
		}):Play()
		Debris:AddItem(star, dur + 0.05)
	end

	local check = Instance.new("ImageLabel")
	check.Name = "PurchaseCheck"
	check.Size = UDim2.fromOffset(0, 0)
	check.AnchorPoint = Vector2.new(0.5, 0.5)
	check.Position = UDim2.fromOffset(centerX, centerY)
	check.BackgroundTransparency = 1
	check.Image = UiAssets.image("icon_check")
	check.ImageColor3 = C.uncommon
	check.ScaleType = Enum.ScaleType.Fit
	check.ZIndex = zIndex + 1
	check.Parent = gui

	local popIn = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local popOut = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(check, popIn, {
		Size = UDim2.fromOffset(checkSize, checkSize),
		ImageTransparency = 0,
	}):Play()
	task.delay(0.42, function()
		if not check.Parent then
			return
		end
		TweenService:Create(check, popOut, {
			Size = UDim2.fromOffset(px(8), px(8)),
			ImageTransparency = 1,
		}):Play()
		Debris:AddItem(check, popOut.Time + 0.05)
	end)
end

local function shouldPlaySound(shopKey: string?): boolean
	if typeof(shopKey) ~= "string" or shopKey == "" then
		return true
	end
	local now = os.clock()
	local last = lastSoundAt[shopKey]
	if last and now - last < SOUND_DEDUP_SEC then
		return false
	end
	lastSoundAt[shopKey] = now
	return true
end

local function animateCard(card: GuiObject, accent: Color3): boolean
	local centerX, centerY = cardCenter(card)
	if not centerX then
		return false
	end
	UiMotion.pop(card, 1.07)
	flashStroke(card, accent)
	spawnBurstAt(centerX, centerY, accent, 240)
	return true
end

local function playCardFx(shopKey: string, accent: Color3, attempt: number, onGiveUp: () -> ())
	local card = findShopCard(shopKey)
	if card and animateCard(card, accent) then
		return
	end
	if attempt >= CARD_LOOKUP_RETRIES then
		onGiveUp()
		return
	end
	task.delay(CARD_LOOKUP_DELAY * attempt, function()
		playCardFx(shopKey, accent, attempt + 1, onGiveUp)
	end)
end

function ShopPurchaseFX.play(opts: PlayOptions?)
	local accent = if opts and opts.accent then opts.accent else C.gold
	local shopKey = if opts and opts.shopKey then opts.shopKey else nil

	if shouldPlaySound(shopKey) then
		SoundManager.play("shop_purchase")
	end

	if typeof(shopKey) ~= "string" or shopKey == "" then
		return
	end

	task.defer(function()
		playCardFx(shopKey, accent, 1, function()
			local centerX, centerY = fallbackBurstCenter()
			spawnBurstAt(centerX, centerY, accent, 240)
		end)
	end)
end

return ShopPurchaseFX
