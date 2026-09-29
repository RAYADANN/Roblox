--!strict
-- ServerMessage.lua — резолвер server-side locale keys для клиента.
--
-- Сервер отдаёт ключи в message / Notify.text (+ опциональные *Params).
-- Клиент вызывает ServerMessage.t / resolveNotifyText перед показом игроку.

local Localization = require(script.Parent.Localization)

local ServerMessage = {}

local KEY_PREFIXES = {
	"server.",
	"quest.",
	"dailyQuest.",
	"shop.",
	"buff.",
	"mutation.",
	"ach.",
	"dailyReward.",
	"layer.",
}

local function looksLikeKey(value: string): boolean
	for _, prefix in ipairs(KEY_PREFIXES) do
		if string.sub(value, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local function localizeValue(value: any): any
	if typeof(value) ~= "string" then
		return value
	end
	if looksLikeKey(value) then
		return Localization.t(value)
	end
	return value
end

local function resolveParams(params: { [string]: any }?): { [string]: any }?
	if params == nil then
		return nil
	end
	local resolved: { [string]: any } = {}
	for key, value in pairs(params) do
		if key == "name" or key == "nameKey" or key == "labelKey" or key == "label" or key == "oreName" then
			local outKey = if key == "nameKey" then "name" elseif key == "labelKey" then "label" else key
			resolved[outKey] = localizeValue(value)
		else
			resolved[key] = value
		end
	end
	return resolved
end

function ServerMessage.formatGrantRewards(params: { [string]: any }?): string
	local p = params or {}
	local parts: { string } = {}
	local coins = p.coins
	local gems = p.gems
	local boostMult = p.boostMult or p.boost
	if typeof(coins) == "number" and coins > 0 then
		table.insert(parts, Localization.t("server.notify.grantCoins", { amount = math.floor(coins) }))
	end
	if typeof(gems) == "number" and gems > 0 then
		table.insert(parts, Localization.t("server.notify.grantGems", { amount = math.floor(gems) }))
	end
	if typeof(boostMult) == "number" and boostMult > 0 then
		table.insert(parts, Localization.t("server.notify.grantBoost", { multiplier = math.floor(boostMult) }))
	end
	if #parts == 0 then
		return Localization.t("server.notify.rewardReceived")
	end
	return table.concat(parts, ", ")
end

function ServerMessage.resolveNotifyText(text: string, textParams: { [string]: any }?): string
	if text == "server.notify.rewardGranted" then
		return ServerMessage.formatGrantRewards(textParams)
	end
	if text == "server.notify.questClaimed" or text == "server.notify.dailyQuestClaimed" then
		local p = textParams or {}
		local name = localizeValue(p.name or p.nameKey or "")
		local rewards = ServerMessage.formatGrantRewards(p)
		return Localization.t(text, { name = name, rewards = rewards })
	end
	return Localization.t(text, resolveParams(textParams))
end

function ServerMessage.t(message: string?, params: { [string]: any }?): string
	if typeof(message) ~= "string" or message == "" then
		return Localization.t("server.error.unknown")
	end
	if message == "server.notify.rewardGranted" then
		return ServerMessage.formatGrantRewards(params)
	end
	if looksLikeKey(message) then
		return Localization.t(message, resolveParams(params))
	end
	return message
end

function ServerMessage.fromResult(result: any, fallbackKey: string): string
	if typeof(result) ~= "table" then
		return Localization.t(fallbackKey)
	end
	if typeof(result.message) ~= "string" or result.message == "" then
		return Localization.t(fallbackKey)
	end
	return ServerMessage.t(result.message, result.messageParams)
end

return ServerMessage
