--!strict
-- Порядок секций и товаров магазина. Данные товаров — Constants.DEVPRODUCTS / GAMEPASSES.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)

export type SectionId = "starter" | "featured" | "boosts" | "coins" | "eggs" | "gamepasses"

export type SectionDef = {
	id: SectionId,
	title: string,
	subtitle: string?,
	iconKey: string,
	accentKey: "shop" | "gold" | "luck" | "damage",
	layout: "hero" | "grid" | "list",
}

-- title/subtitle хранят locale-ключи (shop.section.{id}.*) → резолвятся в
-- ShopPanel.sectionHeader через locShopText (совместимо с ServerMessage).
local SECTIONS: { SectionDef } = {
	{
		id = "starter",
		title = "shop.section.starter.title",
		subtitle = "shop.section.starter.subtitle",
		iconKey = "icon_gift",
		accentKey = "shop",
		layout = "hero",
	},
	{
		id = "featured",
		title = "shop.section.featured.title",
		subtitle = "shop.section.featured.subtitle",
		iconKey = "icon_sparkle",
		accentKey = "gold",
		layout = "hero",
	},
	{
		id = "boosts",
		title = "shop.section.boosts.title",
		subtitle = "shop.section.boosts.subtitle",
		iconKey = "buff_luck",
		accentKey = "luck",
		layout = "grid",
	},
	{
		id = "coins",
		title = "shop.section.coins.title",
		subtitle = "shop.section.coins.subtitle",
		iconKey = "coin",
		accentKey = "gold",
		layout = "list",
	},
	{
		id = "eggs",
		title = "shop.section.eggs.title",
		subtitle = "shop.section.eggs.subtitle",
		iconKey = "icon_egg",
		accentKey = "shop",
		layout = "list",
	},
	{
		id = "gamepasses",
		title = "shop.section.gamepasses.title",
		subtitle = "shop.section.gamepasses.subtitle",
		iconKey = "icon_crown",
		accentKey = "shop",
		layout = "list",
	},
}

local PRODUCT_ORDER: { [SectionId]: { string } } = {
	starter = { "starterPack" },
	featured = { "bundleMiner", "bundleMega" },
	boosts = {
		"boostLuck15",
		"boostLuck60",
		"boostCoins15",
		"boostCoins60",
		"boostDamage15",
		"boostSpeed15",
	},
	coins = { "coinsSmall", "coinsMedium", "coinsLarge", "coinsMega" },
	eggs = { "egg5", "egg10", "egg25" },
	gamepasses = {},
}

local GAMEPASS_ORDER = { "vip", "autoSell", "petSlots" }

local ShopCatalog = {}

function ShopCatalog.sections(): { SectionDef }
	return SECTIONS
end

function ShopCatalog.productKeys(sectionId: SectionId): { string }
	return PRODUCT_ORDER[sectionId] or {}
end

function ShopCatalog.gamepassKeys(): { string }
	return GAMEPASS_ORDER
end

function ShopCatalog.productDef(key: string): any?
	local def = (Constants.DEVPRODUCTS or {})[key]
	if typeof(def) == "table" then
		return def
	end
	return nil
end

function ShopCatalog.gamepassDef(key: string): any?
	local def = (Constants.GAMEPASSES or {})[key]
	if typeof(def) == "table" then
		return def
	end
	return nil
end

return ShopCatalog
