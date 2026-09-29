--!strict
-- EngagementAnalytics — UI и соц-действия для Creator Analytics.
-- Custom Events: ui_open_shop, ui_social_favorite_added, …
-- Funnel: ui_engagement (Creator Hub → Analytics → Funnels).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modules = ReplicatedStorage:WaitForChild("Packages")

local Net = require(modules.Net)
local GameAnalytics = require(script.Parent.GameAnalytics)

export type EngagementKey = string

local FUNNEL = "ui_engagement"

local PANEL_KEYS: { [string]: string } = {
	inventory = "open_inventory",
	upgrades = "open_upgrades",
	stats = "open_stats",
	rebirth = "open_rebirth",
	leaderboard = "open_leaderboard",
	pets = "open_pets",
	shop = "open_shop",
	journal = "open_journal",
	goals = "open_goals",
}

local CLIENT_KEYS: { [string]: boolean } = {
	open_inventory = true,
	open_upgrades = true,
	open_stats = true,
	open_rebirth = true,
	open_leaderboard = true,
	open_pets = true,
	open_shop = true,
	open_journal = true,
	open_goals = true,
	modal_social = true,
	modal_daily = true,
	modal_promo = true,
	modal_egg_shop = true,
	social_favorite_prompt = true,
	social_group_prompt = true,
}

local FUNNEL_BY_KEY: { [string]: { step: number, name: string } } = {
	open_any_panel = { step = 1, name = "opened_panel" },
	open_shop = { step = 2, name = "opened_shop" },
	open_upgrades = { step = 3, name = "opened_upgrades" },
	modal_social = { step = 4, name = "opened_social_modal" },
	social_favorite_prompt = { step = 5, name = "favorite_prompt" },
	social_favorite_added = { step = 6, name = "favorite_added" },
	social_reward_claimed = { step = 7, name = "social_reward_claimed" },
	social_group_verified = { step = 9, name = "group_verified" },
	modal_egg_shop = { step = 8, name = "opened_egg_shop" },
}

local sessionSent: { [number]: { [string]: boolean } } = {}

local EVENT_TO_TAB: { [string]: string } = {}
for tabId, eventKey in PANEL_KEYS do
	EVENT_TO_TAB[eventKey] = tabId
end

local EngagementAnalytics = {}

function EngagementAnalytics.init()
	Net:Handle("TrackEngagement", function(player: Player, key: any, value: any)
		if typeof(key) ~= "string" or not CLIENT_KEYS[key] then
			return { success = false, error = "invalid_key" }
		end
		local numericValue = if typeof(value) == "number" then math.floor(value) else 1
		local tabId = EVENT_TO_TAB[key]
		if tabId then
			EngagementAnalytics.trackPanel(player, tabId)
		else
			EngagementAnalytics.trackOnce(player, key, numericValue)
		end
		return { success = true }
	end)
end

function EngagementAnalytics.onSessionEnd(player: Player)
	sessionSent[player.UserId] = nil
end

local function emit(player: Player, key: string, value: number)
	GameAnalytics.track(player, "ui_" .. key, value)
	local funnel = FUNNEL_BY_KEY[key]
	if funnel then
		GameAnalytics.trackFunnel(player, FUNNEL, funnel.step, funnel.name)
	end
end

function EngagementAnalytics.trackOnce(player: Player, key: string, value: number?)
	if not player or not player.Parent then
		return
	end
	local sent = sessionSent[player.UserId]
	if not sent then
		sent = {}
		sessionSent[player.UserId] = sent
	end
	if sent[key] then
		return
	end
	sent[key] = true
	emit(player, key, value or 1)
end

function EngagementAnalytics.track(player: Player, key: string, value: number?)
	if not player or not player.Parent then
		return
	end
	emit(player, key, value or 1)
end

function EngagementAnalytics.trackPanel(player: Player, tabId: string)
	local key = PANEL_KEYS[tabId]
	if not key then
		return
	end
	EngagementAnalytics.trackOnce(player, "open_any_panel")
	EngagementAnalytics.trackOnce(player, key)
end

function EngagementAnalytics.onFavoriteAdded(player: Player)
	EngagementAnalytics.track(player, "social_favorite_added")
end

function EngagementAnalytics.onSocialRewardClaimed(player: Player)
	EngagementAnalytics.track(player, "social_reward_claimed")
end

function EngagementAnalytics.onGroupVerified(player: Player)
	EngagementAnalytics.trackOnce(player, "social_group_verified")
end

return EngagementAnalytics
