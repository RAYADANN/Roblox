--!strict
-- Клиентские действия соц-награды (группа + избранное + claim).

local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)
local peek = Fusion.peek
local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)

local Notification = require(script.Parent.Parent.Parent.Notification)
local theme = require(script.Parent.Parent.theme)
local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)
local Logger = require(ReplicatedStorage:WaitForChild("shared").util.Logger)
local SocialRewardLogic = require(ReplicatedStorage:WaitForChild("shared").util.SocialRewardLogic)
local EngagementTracker = require(script.Parent.Parent.Parent.util.EngagementTracker)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t
local ServerMessage = require(ReplicatedStorage:WaitForChild("shared").loc.ServerMessage)

local C = theme.C
local SUCCESS_GOLD = Color3.fromRGB(255, 210, 50)
local GAME_FAVORITE_TYPE = Enum.AvatarItemType.Asset

local SocialRewardActions = {}

local log = Logger.new("SocialReward", if RunService:IsStudio() then "DEBUG" else "WARN")
local favoriteListenerReady = false
local _refreshing = false

local function notifyStudioUnavailable(action: string)
	local msg = L("modal.social.promptsUnavailableStudio")
	log:warn(action, "unavailable in Studio — use /social group or fav for testing")
	Notification.show({ text = msg, color = C.closeBg, duration = 4.5 })
end

local function favoritePlaceId(): number
	local configured = SocialRewardLogic.placeId()
	if configured > 0 then
		return configured
	end
	if game.PlaceId > 0 then
		return game.PlaceId
	end
	return 0
end

function SocialRewardActions.refreshStatus(withRetry: boolean?): boolean?
	if _refreshing then
		return nil
	end
	_refreshing = true
	local inGroup: boolean? = nil
	local ok, result = pcall(function()
		if withRetry then
			return Net:Invoke("ConfirmSocialGroup")
		end
		return Net:Invoke("RefreshSocialStatus")
	end)
	_refreshing = false
	if not ok then
		log:warn("refreshStatus failed:", result)
		return nil
	end
	if typeof(result) == "table" and result.inGroup == true then
		inGroup = true
	elseif typeof(result) == "table" and result.inGroup == false then
		inGroup = false
	end
	return inGroup
end

function SocialRewardActions.ensureStatusFresh()
	SocialRewardActions.refreshStatus(false)
end

local function confirmGroupMembership(): boolean
	local ok, result = pcall(function()
		return Net:Invoke("ConfirmSocialGroup")
	end)
	if not ok or typeof(result) ~= "table" then
		log:warn("ConfirmSocialGroup failed:", result)
		return false
	end
	return result.success == true and result.inGroup == true
end

local function ensureFavoriteListener()
	if favoriteListenerReady then
		return
	end
	favoriteListenerReady = true
	AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(result: Enum.AvatarPromptResult)
		if result ~= Enum.AvatarPromptResult.Success then
			return
		end
		pcall(function()
			local ok, invokeResult = Net:Invoke("ConfirmSocialFavorite")
			if ok and typeof(invokeResult) == "table" and invokeResult.success then
				Notification.show({
					text = L("modal.social.stepFavoriteDone"),
					color = C.sell,
					duration = 2.5,
				})
			end
		end)
	end)
end

function SocialRewardActions.statusMark(done: boolean): string
	return if done then "✓" else "✗"
end

function SocialRewardActions.rewardSummary(): string
	local rewards = (Constants.SOCIAL_REWARD or {}).rewards or {}
	local parts: { string } = {}
	if rewards.coins and rewards.coins > 0 then
		table.insert(parts, L("modal.reward.coins", { n = rewards.coins }))
	end
	if rewards.gems and rewards.gems > 0 then
		table.insert(parts, L("modal.reward.gems", { n = rewards.gems }))
	end
	if rewards.boost then
		table.insert(parts, L("modal.reward.boost", { n = math.floor(rewards.boost.multiplier or 2) }))
	end
	return table.concat(parts, "  ·  ")
end

function SocialRewardActions.promptGroup(_isBusy: any)
	local groupId = SocialRewardLogic.groupId()
	if groupId <= 0 then
		Notification.show({ text = L("modal.social.groupNotConfigured"), color = C.closeBg, duration = 3 })
		return
	end

	if confirmGroupMembership() then
		Notification.show({
			text = L("modal.social.stepGroupDone"),
			color = C.sell,
			duration = 2.5,
		})
		return
	end

	Notification.show({
		text = L("modal.social.openingGroupPrompt"),
		color = C.textMain,
		duration = 2,
	})

	if RunService:IsStudio() then
		if confirmGroupMembership() then
			Notification.show({
				text = L("modal.social.stepGroupDone"),
				color = C.sell,
				duration = 2.5,
			})
		else
			notifyStudioUnavailable("PromptJoinAsync")
		end
		return
	end

	EngagementTracker.track("social_group_prompt")

	task.spawn(function()
		local ok, result = pcall(function()
			return GroupService:PromptJoinAsync(groupId)
		end)
		if not ok then
			log:warn("PromptJoinAsync failed:", result)
			Notification.show({ text = L("modal.social.groupPromptFailed"), color = C.closeBg, duration = 3.5 })
			return
		end

		if result ~= Enum.GroupMembershipStatus.Joined
			and result ~= Enum.GroupMembershipStatus.AlreadyMember then
			Notification.show({
				text = L("modal.social.groupJoinIncomplete"),
				color = C.closeBg,
				duration = 4,
			})
			return
		end

		if confirmGroupMembership() then
			Notification.show({
				text = L("modal.social.stepGroupDone"),
				color = C.sell,
				duration = 2.5,
			})
			return
		end

		Notification.show({
			text = L("modal.social.groupVerifyFailed"),
			color = C.closeBg,
			duration = 4.5,
		})
	end)
end

function SocialRewardActions.promptFavorite(_isBusy: any)
	ensureFavoriteListener()
	local placeId = favoritePlaceId()
	if placeId <= 0 then
		Notification.show({ text = L("modal.social.gameNotConfigured"), color = C.closeBg, duration = 3 })
		return
	end

	Notification.show({
		text = L("modal.social.openingFavoritePrompt"),
		color = C.textMain,
		duration = 2,
	})

	if RunService:IsStudio() then
		local ok, result = pcall(function()
			return Net:Invoke("ConfirmSocialFavorite")
		end)
		if ok and typeof(result) == "table" and result.success then
			Notification.show({
				text = L("modal.social.stepFavoriteDone"),
				color = C.sell,
				duration = 2.5,
			})
		else
			notifyStudioUnavailable("PromptSetFavorite")
		end
		return
	end

	EngagementTracker.track("social_favorite_prompt")

	local ok, err = pcall(function()
		AvatarEditorService:PromptSetFavorite(placeId, GAME_FAVORITE_TYPE, true)
	end)
	if not ok then
		log:warn("PromptSetFavorite failed:", err)
		Notification.show({ text = L("modal.social.favoritePromptFailed"), color = C.closeBg, duration = 3.5 })
	end
end

function SocialRewardActions.tryClaim(isBusy: any, onComplete: ((boolean) -> ())?)
	if peek(isBusy) then
		return
	end
	isBusy:set(true)
	task.spawn(function()
		SocialRewardActions.refreshStatus(true)
		task.wait(0.2)
		local ok, result = pcall(function()
			return Net:Invoke("ClaimSocialReward")
		end)
		isBusy:set(false)
		if not ok then
			Notification.show({ text = L("modal.common.netError"), color = C.closeBg, duration = 3 })
			if onComplete then
				onComplete(false)
			end
			return
		end
		if typeof(result) == "table" and result.success then
			Notification.show({
				text = ServerMessage.t(result.message, result.messageParams),
				color = SUCCESS_GOLD,
				icon = "icon_gift",
				duration = 4.5,
			})
			pcall(function()
				local RewardFX = require(script.Parent.Parent.Parent.RewardFX)
				RewardFX.burst("epic")
			end)
			if onComplete then
				onComplete(true)
			end
			return
		end
		local msg = ServerMessage.fromResult(result, "modal.social.conditionsNotMet")
		Notification.show({ text = msg, color = C.closeBg, duration = 3.5 })
		if onComplete then
			onComplete(false)
		end
	end)
end

ensureFavoriteListener()

return SocialRewardActions
