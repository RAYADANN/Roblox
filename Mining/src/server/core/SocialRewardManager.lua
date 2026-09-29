--!strict
-- SocialRewardManager.lua — награда за группу + избранное.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local modules = ReplicatedStorage:WaitForChild("Packages")

local Logger = require(shared.util.Logger)
local Constants = require(shared.constants)
local SocialRewardLogic = require(shared.util.SocialRewardLogic)
local EngagementAnalytics = require(script.Parent.EngagementAnalytics)
local PlayerBoosts = require(script.Parent.PlayerBoosts)
local Net = require(modules.Net)

export type Deps = {
	profileManager: any,
	onProfileChanged: ((player: Player) -> ())?,
	notify: ((player: Player, payload: any) -> ())?,
}

local GOLD = { r = 255, g = 210, b = 50 }

local VERIFY_ATTEMPTS = 10
local VERIFY_DELAY_SEC = 0.45

local SocialRewardManager = {}
SocialRewardManager.__index = SocialRewardManager

function SocialRewardManager.new(deps: Deps)
	local self = setmetatable({}, SocialRewardManager)
	self._log = Logger.new("SocialReward")
	self._profileManager = deps.profileManager
	self._onProfileChanged = deps.onProfileChanged
	self._notify = deps.notify
	self._groupCache = {} :: { [number]: boolean }
	self._devInGroup = {} :: { [number]: boolean }

	Net:Handle("ConfirmSocialFavorite", function(player: Player)
		return self:_handleConfirmFavorite(player)
	end)

	Net:Handle("ConfirmSocialGroup", function(player: Player)
		return self:_handleConfirmGroup(player)
	end)

	Net:Handle("ClaimSocialReward", function(player: Player)
		return self:_handleClaim(player)
	end)

	Net:Handle("RefreshSocialStatus", function(player: Player)
		local inGroup = self:refreshGroup(player, false)
		return { success = true, inGroup = inGroup }
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._groupCache[player.UserId] = nil
		self._devInGroup[player.UserId] = nil
	end)

	return self
end

function SocialRewardManager:_data(player: Player)
	return self._profileManager:getData(player)
end

function SocialRewardManager:_sync(player: Player)
	if self._onProfileChanged then
		self._onProfileChanged(player)
	end
end

function SocialRewardManager:_groupRank(player: Player): number
	if RunService:IsStudio() and self._devInGroup[player.UserId] == true then
		return 1
	end
	local groupId = SocialRewardLogic.groupId()
	if groupId <= 0 then
		return 0
	end
	local ok, rank = pcall(function()
		return player:GetRankInGroupAsync(groupId)
	end)
	if not ok then
		self._log:warn("GetRankInGroupAsync failed for", player.UserId, rank)
		return 0
	end
	return math.max(0, math.floor(rank or 0))
end

function SocialRewardManager:_queryGroupMembership(player: Player): boolean
	return self:_groupRank(player) > 0
end

function SocialRewardManager:_verifyGroupMembership(
	player: Player,
	attempts: number?,
	delaySec: number?
): boolean
	local maxAttempts = attempts or VERIFY_ATTEMPTS
	local waitSec = delaySec or VERIFY_DELAY_SEC
	for attempt = 1, maxAttempts do
		self._groupCache[player.UserId] = nil
		if self:_queryGroupMembership(player) then
			self._groupCache[player.UserId] = true
			return true
		end
		if attempt < maxAttempts then
			task.wait(waitSec)
		end
	end
	return false
end

function SocialRewardManager:_markGroupVerified(player: Player)
	local data = self:_data(player)
	if not data then
		return
	end
	SocialRewardLogic.ensureFields(data)
	data.socialGroupConfirmed = true
	self._groupCache[player.UserId] = true
end

function SocialRewardManager:isInGroup(player: Player): boolean
	local data = self:_data(player)
	if data and data.socialGroupConfirmed == true then
		return true
	end
	if self._groupCache[player.UserId] == true then
		return true
	end
	local inGroup = self:_queryGroupMembership(player)
	if inGroup then
		self._groupCache[player.UserId] = true
		if data then
			data.socialGroupConfirmed = true
		end
	end
	return inGroup
end

function SocialRewardManager:refreshGroup(player: Player, withRetry: boolean?): boolean
	self._groupCache[player.UserId] = nil
	local inGroup = if withRetry
		then self:_verifyGroupMembership(player)
		else self:_queryGroupMembership(player)
	if inGroup then
		self:_markGroupVerified(player)
	end
	self:_sync(player)
	return inGroup
end

function SocialRewardManager:buildPayload(player: Player)
	local data = self:_data(player)
	if not data then
		return SocialRewardLogic.buildPayload({}, false)
	end
	SocialRewardLogic.ensureFields(data)
	local inGroup = data.socialGroupConfirmed == true or self:isInGroup(player)
	return SocialRewardLogic.buildPayload(data, inGroup)
end

function SocialRewardManager:devSetInGroup(player: Player, inGroup: boolean)
	if not RunService:IsStudio() then
		return
	end
	self._devInGroup[player.UserId] = inGroup
	self._groupCache[player.UserId] = inGroup
	local data = self:_data(player)
	if data and inGroup then
		data.socialGroupConfirmed = true
	end
	self:_sync(player)
end

function SocialRewardManager:devReset(player: Player)
	if not RunService:IsStudio() then
		return
	end
	local data = self:_data(player)
	if not data then
		return
	end
	data.socialRewardClaimed = false
	data.socialRewardPromptSeen = false
	data.socialFavoriteConfirmed = false
	data.socialGroupConfirmed = false
	self._devInGroup[player.UserId] = nil
	self._groupCache[player.UserId] = nil
	self:_sync(player)
end

function SocialRewardManager:_grantRewards(data: any): { [string]: any }
	local cfg = Constants.SOCIAL_REWARD or {}
	local rewards = cfg.rewards or {}
	local grant: { [string]: any } = {}

	if rewards.coins and rewards.coins > 0 then
		local amt = math.floor(rewards.coins)
		data.coins = (data.coins or 0) + amt
		data.totalCoinsEarned = (data.totalCoinsEarned or 0) + amt
		grant.coins = amt
	end
	if rewards.gems and rewards.gems > 0 then
		local amt = math.floor(rewards.gems)
		data.gems = (data.gems or 0) + amt
		grant.gems = amt
	end
	if rewards.boost and typeof(rewards.boost) == "table" then
		local boosts = data.activeBoosts
		if typeof(boosts) ~= "table" then
			boosts = {}
			data.activeBoosts = boosts
		end
		PlayerBoosts.addBoost(boosts, {
			kind = rewards.boost.kind or "coins",
			multiplier = rewards.boost.multiplier or 2,
			durationSec = rewards.boost.durationSec or 600,
			source = "social_reward",
		})
		grant.boostMult = math.floor(rewards.boost.multiplier or 2)
	end

	return grant
end

function SocialRewardManager:_handleConfirmFavorite(player: Player)
	local data = self:_data(player)
	if not data then
		return { success = false, error = "no_profile", message = "server.error.noProfile" }
	end
	SocialRewardLogic.ensureFields(data)
	if data.socialRewardClaimed then
		return { success = false, error = "claimed", message = "server.error.rewardClaimed" }
	end
	data.socialFavoriteConfirmed = true
	EngagementAnalytics.onFavoriteAdded(player)
	self:_sync(player)
	return { success = true }
end

function SocialRewardManager:_handleConfirmGroup(player: Player)
	local data = self:_data(player)
	if not data then
		return { success = false, error = "no_profile", message = "server.error.noProfile" }
	end
	SocialRewardLogic.ensureFields(data)
	if data.socialRewardClaimed then
		return { success = false, error = "claimed", message = "server.error.rewardClaimed" }
	end

	local inGroup = self:_verifyGroupMembership(player)
	if inGroup then
		self:_markGroupVerified(player)
		EngagementAnalytics.onGroupVerified(player)
		self:_sync(player)
		self._log:info("Group verified for", player.UserId, "rank", self:_groupRank(player))
		return { success = true, inGroup = true }
	end

	self:_sync(player)
	self._log:info("Group NOT verified for", player.UserId, "rank", self:_groupRank(player))
	return {
		success = false,
		error = "group",
		inGroup = false,
		message = "server.error.joinGroup",
	}
end

function SocialRewardManager:_handleClaim(player: Player)
	local data = self:_data(player)
	if not data then
		return { success = false, error = "no_profile", message = "server.error.noProfile" }
	end
	SocialRewardLogic.ensureFields(data)

	if data.socialRewardClaimed then
		return { success = false, error = "claimed", message = "server.error.rewardClaimed" }
	end
	if not SocialRewardLogic.isConfigured() then
		return { success = false, error = "not_configured", message = "server.error.rewardNotConfigured" }
	end
	if not data.socialFavoriteConfirmed then
		return { success = false, error = "favorite", message = "server.error.addFavorite" }
	end

	self._groupCache[player.UserId] = nil
	if not self:_verifyGroupMembership(player) then
		data.socialGroupConfirmed = false
		self:_sync(player)
		return { success = false, error = "group", message = "server.error.joinGroup" }
	end

	self:_markGroupVerified(player)
	data.socialRewardClaimed = true
	local grantInfo = self:_grantRewards(data)
	EngagementAnalytics.onSocialRewardClaimed(player)

	self:_sync(player)
	self._log:info("Claimed by", player.UserId)
	return { success = true, message = "server.notify.rewardGranted", messageParams = grantInfo }
end

function SocialRewardManager:onProfileLoaded(player: Player)
	local data = self:_data(player)
	if not data then
		return
	end
	SocialRewardLogic.ensureFields(data)

	task.spawn(function()
		if data.socialGroupConfirmed or self:_queryGroupMembership(player) then
			self:_markGroupVerified(player)
		end
		self:_sync(player)
	end)

	if data.socialRewardClaimed or not SocialRewardLogic.isConfigured() then
		return
	end

	if not data.socialRewardPromptSeen then
		data.socialRewardPromptSeen = true
		if self._notify then
			self._notify(player, {
				text = "server.notify.socialRewardPrompt",
				icon = "icon_gift",
				color = GOLD,
				duration = 6,
				kind = "social_reward_available",
			})
		end
	end
end

return SocialRewardManager
