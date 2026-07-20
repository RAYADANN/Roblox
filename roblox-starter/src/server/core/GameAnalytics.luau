--!strict

local AnalyticsService = game:GetService("AnalyticsService")

local GameAnalytics = {}

function GameAnalytics.log(player: Player, eventName: string, value: number?)
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
	if not ok then
		warn(`[GameAnalytics] {eventName}: {err}`)
	end
end

return GameAnalytics
