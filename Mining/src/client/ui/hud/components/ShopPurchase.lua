--!strict
-- Покупка товара / gamepass из ShopPanel и EggShopModal.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)
local Notification = require(script.Parent.Parent.Parent.Notification)
local ShopPurchaseFX = require(script.Parent.Parent.Parent.ShopPurchaseFX)
local RobuxPurchaseFX = require(script.Parent.Parent.Parent.RobuxPurchaseFX)

export type PromptItem = {
	key: string?,
	id: number,
	name: string,
	kind: "gamepass" | "product",
}

local ShopPurchase = {}

local _hooksReady = false
local _pendingKey: string? = nil
local _pendingName: string? = nil
local _pendingTier: ("shop" | "egg" | "gamepass")? = nil

local function resolveTier(shopKey: string?): "shop" | "egg" | "gamepass"
	if typeof(shopKey) ~= "string" or shopKey == "" then
		return "shop"
	end
	if (Constants.GAMEPASSES or {})[shopKey] then
		return "gamepass"
	end
	if string.sub(shopKey, 1, 4) == "egg_" then
		return "egg"
	end
	return "shop"
end

local function onPromptFinished(wasPurchased: boolean)
	if not wasPurchased then
		_pendingKey = nil
		_pendingName = nil
		_pendingTier = nil
		return
	end
	local shopKey = _pendingKey
	local productName = _pendingName
	local tier = _pendingTier or resolveTier(shopKey)
	_pendingKey = nil
	_pendingName = nil
	_pendingTier = nil

	RobuxPurchaseFX.play({
		shopKey = shopKey,
		productName = productName,
		tier = tier,
	})
	if typeof(shopKey) == "string" and shopKey ~= "" then
		ShopPurchaseFX.play({ shopKey = shopKey })
	end
end

local function ensureHooks()
	if _hooksReady then
		return
	end
	_hooksReady = true

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_player, _passId, wasPurchased)
		onPromptFinished(wasPurchased)
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(_userId, _productId, wasPurchased)
		onPromptFinished(wasPurchased)
	end)
end

function ShopPurchase.prompt(item: PromptItem)
	if item.id == 0 then
		Notification.show({
			text = "ID не настроен в Creator Hub. В Studio: /grantpass или /grantproduct",
			icon = "tab_upgrades",
			color = Color3.fromRGB(120, 200, 255),
			duration = 3,
		})
		return
	end

	ensureHooks()
	if typeof(item.key) == "string" and item.key ~= "" then
		_pendingKey = item.key
	else
		_pendingKey = nil
	end
	_pendingName = item.name
	_pendingTier = if item.kind == "gamepass" then "gamepass" else resolveTier(item.key)

	pcall(function()
		local player = Players.LocalPlayer
		if item.kind == "gamepass" then
			MarketplaceService:PromptGamePassPurchase(player, item.id)
		else
			MarketplaceService:PromptProductPurchase(player, item.id)
		end
	end)
end

return ShopPurchase
