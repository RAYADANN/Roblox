--!strict
-- PromoCodeManager.lua — серверная активация промокодов.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local modules = ReplicatedStorage:WaitForChild("Packages")

local Logger = require(shared.util.Logger)
local PromoCodeLogic = require(shared.util.PromoCodeLogic)
local PlayerBoosts = require(script.Parent.PlayerBoosts)
local Net = require(modules.Net)

export type Deps = {
	profileManager: any,
	onProfileChanged: ((player: Player) -> ())?,
	notify: ((player: Player, payload: any) -> ())?,
}

local GLOBAL_STORE = "PromoCodeGlobal_v1"

local PromoCodeManager = {}
PromoCodeManager.__index = PromoCodeManager

function PromoCodeManager.new(deps: Deps)
	local self = setmetatable({}, PromoCodeManager)
	self._log = Logger.new("PromoCode")
	self._profileManager = deps.profileManager
	self._onProfileChanged = deps.onProfileChanged
	self._notify = deps.notify
	self._globalStore = DataStoreService:GetDataStore(GLOBAL_STORE)
	self._redeemBusy = {} :: { [number]: boolean }
	self._studioGlobalCounts = {} :: { [string]: number }

	Net:Handle("RedeemCode", function(player: Player, rawCode: string)
		return self:_handleRedeem(player, rawCode)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._redeemBusy[player.UserId] = nil
	end)
	self._log:info("PromoCodeManager initialized")
	return self
end

function PromoCodeManager:_data(player: Player)
	return self._profileManager:getData(player)
end

function PromoCodeManager:_sync(player: Player)
	if self._onProfileChanged then
		self._onProfileChanged(player)
	end
end

function PromoCodeManager:onProfileLoaded(player: Player)
	local data = self:_data(player)
	if data then
		PromoCodeLogic.ensureRedeemed(data)
	end
end

function PromoCodeManager:_reserveGlobalSlot(code: string, maxRedemptions: number): (boolean, string?)
	if RunService:IsStudio() then
		local count = self._studioGlobalCounts[code] or 0
		if count >= maxRedemptions then
			return false, "exhausted"
		end
		self._studioGlobalCounts[code] = count + 1
		return true, nil
	end

	local key = "code_" .. code
	local ok, result = pcall(function()
		return self._globalStore:UpdateAsync(key, function(old)
			local count = if typeof(old) == "number" then old else 0
			if count >= maxRedemptions then
				return nil
			end
			return count + 1
		end)
	end)
	if not ok then
		self._log:warn("Global promo DS failed for", code, result)
		return false, "store_error"
	end
	if result == nil then
		return false, "exhausted"
	end
	return true, nil
end

function PromoCodeManager:_grantReward(data: any, reward: any): { [string]: any }
	local grant: { [string]: any } = {}
	if reward.coins and reward.coins > 0 then
		local amt = math.floor(reward.coins)
		data.coins = (data.coins or 0) + amt
		data.totalCoinsEarned = (data.totalCoinsEarned or 0) + amt
		grant.coins = amt
	end
	if reward.gems and reward.gems > 0 then
		local amt = math.floor(reward.gems)
		data.gems = (data.gems or 0) + amt
		grant.gems = amt
	end
	if reward.boost and typeof(reward.boost) == "table" then
		local boosts = data.activeBoosts
		if typeof(boosts) ~= "table" then
			boosts = {}
			data.activeBoosts = boosts
		end
		PlayerBoosts.addBoost(boosts, {
			kind = reward.boost.kind or "coins",
			multiplier = reward.boost.multiplier or 2,
			durationSec = reward.boost.durationSec or 600,
			source = "promo_code",
		})
		grant.boostMult = math.floor(reward.boost.multiplier or 2)
	end
	return grant
end

function PromoCodeManager:_handleRedeem(player: Player, rawCode: string)
	if self._redeemBusy[player.UserId] then
		return { success = false, error = "busy", message = "server.error.promoBusy" }
	end
	if typeof(rawCode) ~= "string" then
		return { success = false, error = "bad_input", message = "server.error.promoBadInput" }
	end

	local data = self:_data(player)
	if not data then
		return { success = false, error = "no_profile", message = "server.error.noProfile" }
	end

	local check = PromoCodeLogic.validate(data, rawCode)
	if not check.ok or not check.def or not check.normalizedCode then
		return {
			success = false,
			error = check.error or "invalid",
			message = check.message or "server.error.promoInvalid",
		}
	end

	local def = check.def
	local code = check.normalizedCode
	self._redeemBusy[player.UserId] = true

	if def.maxRedemptions then
		local reserved, err = self:_reserveGlobalSlot(code, def.maxRedemptions)
		if not reserved then
			self._redeemBusy[player.UserId] = nil
			if err == "exhausted" then
				return { success = false, error = "exhausted", message = "server.error.promoExhausted" }
			end
			return { success = false, error = "store_error", message = "server.error.promoStoreError" }
		end
	end

	local redeemed = PromoCodeLogic.ensureRedeemed(data)
	redeemed[code] = true
	local grantInfo = self:_grantReward(data, def.reward)
	self._redeemBusy[player.UserId] = nil

	self:_sync(player)
	self._log:info("Redeemed", code, "for", player.UserId)
	return { success = true, message = "server.notify.rewardGranted", messageParams = grantInfo, code = code }
end

return PromoCodeManager
