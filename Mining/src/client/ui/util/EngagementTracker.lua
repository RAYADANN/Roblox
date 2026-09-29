--!strict
-- Клиент → сервер: UI-открытия и соц-промпты (сервер дедупит по сессии).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)
local Logger = require(ReplicatedStorage:WaitForChild("shared").util.Logger)

local log = Logger.new("EngagementTracker", "WARN")

local EngagementTracker = {}

local function send(key: string, value: number?)
	task.spawn(function()
		local ok, err = pcall(function()
			Net:Invoke("TrackEngagement", key, value)
		end)
		if not ok then
			log:warn("TrackEngagement failed:", key, err)
		end
	end)
end

function EngagementTracker.track(key: string, value: number?)
	send(key, value)
end

function EngagementTracker.trackPanel(tabId: string)
	send("open_" .. tabId)
end

function EngagementTracker.trackModal(kind: "social" | "daily" | "promo" | "egg_shop")
	send("modal_" .. kind)
end

return EngagementTracker
