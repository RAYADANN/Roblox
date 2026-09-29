--!strict
-- AnalyticsService wrapper для soft launch.
-- Все события — server-authoritative (Roblox Creator Analytics).

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")

export type FunnelStep = {
	step: number,
	name: string,
}

local GameAnalytics = {}

GameAnalytics.FUNNEL_ONBOARDING = "onboarding"
GameAnalytics.FUNNEL_SESSION = "session_progression"
GameAnalytics.FUNNEL_UI = "ui_engagement"

local DEPTH_MILESTONES = { 50, 100, 250, 500, 1000, 2500, 5000 }

-- Roblox принимает funnel steps только 1..100. Игровой tutorialStep = 0..3.
local ONBOARDING_FUNNEL_BY_TUTORIAL_STEP = {
	[1] = { step = 2, name = "mined_first_block" },
	[2] = { step = 3, name = "sold_first_ore" },
	[3] = { step = 4, name = "tutorial_completed" },
}

local sessionJoinAt: { [number]: number } = {}
local funnelSessionId: { [number]: string } = {}
local onboardingStepsSent: { [number]: { [number]: boolean } } = {}
local customFunnelStepsSent: { [number]: { [string]: { [number]: boolean } } } = {}

local function safeCall(label: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok and RunService:IsStudio() then
		warn("[GameAnalytics]", label, err)
	end
end

function GameAnalytics.track(player: Player, eventName: string, value: number?)
	if not player or not player.Parent then
		return
	end
	safeCall("track:" .. eventName, function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
end

function GameAnalytics.trackOnboarding(player: Player, step: number, stepName: string)
	if not player or not player.Parent then
		return
	end
	if step < 1 or step > 100 then
		if RunService:IsStudio() then
			warn("[GameAnalytics] onboarding step out of range:", step, stepName)
		end
		return
	end

	local sent = onboardingStepsSent[player.UserId]
	if not sent then
		sent = {}
		onboardingStepsSent[player.UserId] = sent
	end
	if sent[step] then
		return
	end
	sent[step] = true

	safeCall("onboarding:" .. stepName, function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

function GameAnalytics.trackTutorialStep(player: Player, tutorialStep: number)
	local mapped = ONBOARDING_FUNNEL_BY_TUTORIAL_STEP[tutorialStep]
	if mapped then
		GameAnalytics.trackOnboarding(player, mapped.step, mapped.name)
	end
end

function GameAnalytics.onboardingSessionStart(player: Player, tutorialStep: number)
	GameAnalytics.trackOnboarding(player, 1, "joined_game")
	if tutorialStep >= 1 then
		GameAnalytics.trackOnboarding(player, 2, "mined_first_block")
	end
	if tutorialStep >= 2 then
		GameAnalytics.trackOnboarding(player, 3, "sold_first_ore")
	end
end

function GameAnalytics.trackFunnel(player: Player, funnelName: string, step: number, stepName: string)
	if not player or not player.Parent then
		return
	end
	if step < 1 or step > 100 then
		if RunService:IsStudio() then
			warn("[GameAnalytics] funnel step out of range:", funnelName, step, stepName)
		end
		return
	end

	local sentByFunnel = customFunnelStepsSent[player.UserId]
	if not sentByFunnel then
		sentByFunnel = {}
		customFunnelStepsSent[player.UserId] = sentByFunnel
	end
	local sent = sentByFunnel[funnelName]
	if not sent then
		sent = {}
		sentByFunnel[funnelName] = sent
	end
	if sent[step] then
		return
	end
	sent[step] = true

	local sessionId = funnelSessionId[player.UserId]
	if not sessionId then
		sessionId = HttpService:GenerateGUID(false)
		funnelSessionId[player.UserId] = sessionId
	end
	safeCall("funnel:" .. funnelName, function()
		AnalyticsService:LogFunnelStepEvent(player, funnelName, sessionId, step, stepName)
	end)
end

function GameAnalytics.trackPurchase(player: Player, productKey: string)
	GameAnalytics.track(player, "robux_purchase", 1)
	GameAnalytics.track(player, "purchase_" .. productKey, 1)
end

function GameAnalytics.trackDepthMilestones(player: Player, prevRecord: number, newDepth: number)
	for _, milestone in ipairs(DEPTH_MILESTONES) do
		if newDepth >= milestone and prevRecord < milestone then
			GameAnalytics.track(player, "depth_milestone", milestone)
		end
	end
end

function GameAnalytics.onSessionStart(player: Player)
	sessionJoinAt[player.UserId] = os.clock()
	funnelSessionId[player.UserId] = HttpService:GenerateGUID(false)
	onboardingStepsSent[player.UserId] = nil
	customFunnelStepsSent[player.UserId] = nil
end

function GameAnalytics.onSessionEnd(player: Player): number
	local joinedAt = sessionJoinAt[player.UserId]
	local durationSec = if joinedAt then math.max(0, math.floor(os.clock() - joinedAt)) else 0
	GameAnalytics.track(player, "session_end", durationSec)
	sessionJoinAt[player.UserId] = nil
	funnelSessionId[player.UserId] = nil
	onboardingStepsSent[player.UserId] = nil
	customFunnelStepsSent[player.UserId] = nil
	return durationSec
end

return GameAnalytics
