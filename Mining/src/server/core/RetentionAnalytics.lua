--!strict
-- RetentionAnalytics — воронка сессии и снимок выхода для Creator Analytics.
-- Смотреть: Creator Hub → Analytics → Funnels (session_progression) и Custom Events (exit_*).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local OreTypes = require(shared.types.OreTypes)

local GameAnalytics = require(script.Parent.GameAnalytics)

export type SessionState = {
	blocksMined: number,
	sold: boolean,
	upgraded: boolean,
	hatched: boolean,
	rebirth: boolean,
}

local FUNNEL_SESSION = "session_progression"

local DEPTH_FUNNEL = {
	{ threshold = 50, step = 6, name = "depth_50" },
	{ threshold = 150, step = 7, name = "depth_150" },
	{ threshold = 500, step = 9, name = "depth_500" },
}

local sessionState: { [number]: SessionState } = {}

local RetentionAnalytics = {}

function RetentionAnalytics.onSessionStart(player: Player)
	sessionState[player.UserId] = {
		blocksMined = 0,
		sold = false,
		upgraded = false,
		hatched = false,
		rebirth = false,
	}
	GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 1, "joined")
end

function RetentionAnalytics.onBlockMined(player: Player)
	local state = sessionState[player.UserId]
	if not state then
		return
	end
	state.blocksMined += 1
	if state.blocksMined == 1 then
		GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 2, "mined_block")
	end
	if state.blocksMined == 10 then
		GameAnalytics.track(player, "session_blocks_10", 1)
	end
	if state.blocksMined == 50 then
		GameAnalytics.track(player, "session_blocks_50", 1)
	end
end

function RetentionAnalytics.onSell(player: Player)
	local state = sessionState[player.UserId]
	if not state or state.sold then
		return
	end
	state.sold = true
	GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 3, "sold_ores")
end

function RetentionAnalytics.onUpgrade(player: Player)
	local state = sessionState[player.UserId]
	if not state or state.upgraded then
		return
	end
	state.upgraded = true
	GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 4, "bought_upgrade")
end

function RetentionAnalytics.onTutorialStep(player: Player, step: number)
	if step < 3 then
		return
	end
	GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 5, "tutorial_done")
end

function RetentionAnalytics.onDepthRecord(player: Player, prevRecord: number, newDepth: number)
	for _, gate in ipairs(DEPTH_FUNNEL) do
		if newDepth >= gate.threshold and prevRecord < gate.threshold then
			GameAnalytics.trackFunnel(player, FUNNEL_SESSION, gate.step, gate.name)
		end
	end
end

function RetentionAnalytics.onHatch(player: Player)
	local state = sessionState[player.UserId]
	if not state or state.hatched then
		return
	end
	state.hatched = true
	GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 8, "hatched_pet")
end

function RetentionAnalytics.onRebirth(player: Player)
	local state = sessionState[player.UserId]
	if not state or state.rebirth then
		return
	end
	state.rebirth = true
	GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 11, "rebirth")
end

local function durationBucket(durationSec: number): string
	if durationSec < 30 then
		return "under_30s"
	end
	if durationSec < 60 then
		return "30s_1m"
	end
	if durationSec < 180 then
		return "1_3m"
	end
	if durationSec < 600 then
		return "3_10m"
	end
	return "10m_plus"
end

local function exitStage(
	data: OreTypes.PlayerData,
	state: SessionState,
	durationSec: number
): (number, string)
	local tutorial = data.tutorialStep or 0
	local depth = data.maxDepthReached or 0

	if durationSec < 60 and state.blocksMined == 0 and tutorial == 0 then
		return 1, "bounce"
	end
	if tutorial < 3 then
		return 2, "tutorial"
	end
	if depth < 50 then
		return 3, "post_tutorial"
	end
	if depth < 150 then
		return 4, "early_depth"
	end
	if depth < 500 then
		return 5, "mid_depth"
	end
	return 6, "deep"
end

function RetentionAnalytics.onSessionEnd(player: Player, data: OreTypes.PlayerData?, durationSec: number)
	local state = sessionState[player.UserId]
	if not state then
		sessionState[player.UserId] = nil
		return
	end

	if durationSec >= 300 then
		GameAnalytics.trackFunnel(player, FUNNEL_SESSION, 10, "session_5min")
	end

	if data then
		local stageId, stageName = exitStage(data, state, durationSec)
		GameAnalytics.track(player, "exit_stage", stageId)
		GameAnalytics.track(player, "exit_stage_" .. stageName, 1)
		GameAnalytics.track(player, "exit_tutorial_step", data.tutorialStep or 0)
		GameAnalytics.track(player, "exit_depth_record", data.maxDepthReached or 0)
		GameAnalytics.track(player, "exit_session_sec", durationSec)
		GameAnalytics.track(player, "exit_blocks_session", state.blocksMined)
		GameAnalytics.track(player, "exit_pickaxe_level", data.pickaxeLevel or 1)
		GameAnalytics.track(player, "exit_rebirths", data.rebirths or 0)
		GameAnalytics.track(player, "exit_duration_" .. durationBucket(durationSec), 1)
	end

	sessionState[player.UserId] = nil
end

return RetentionAnalytics
