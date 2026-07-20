--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("NightRaidRemotes")
ReplicatedStorage:WaitForChild("shared")

local packages = ReplicatedStorage:FindFirstChild("Packages")
if not packages then
	warn("[NightRaid] Packages missing — restart rojo serve + reconnect plugin")
	packages = ReplicatedStorage:WaitForChild("Packages", 30)
end
assert(packages, "[NightRaid] Packages still missing")

local ViewportLayout = require(script.ui.util.ViewportLayout)
local UiScreen = require(script.ui.util.UiScreen)
local FlashlightController = require(script.core.FlashlightController)
local StealController = require(script.core.StealController)
local BuildController = require(script.core.BuildController)

local React = require(packages.React)
local ReactRoblox = require(packages.ReactRoblox)
local GameRoot = require(script.ui.GameRoot)

ViewportLayout.start()

local flashlight = FlashlightController.new()
local steal = StealController.new()
local build = BuildController.new(function()
	local id = Players.LocalPlayer:GetAttribute("SelectedBlockId")
	if typeof(id) == "string" then
		return id
	end
	return "dirt"
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = UiScreen.ensure(playerGui, "NightRaidUI", "hud")
local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(GameRoot))

print("[NightRaid] Client — Hub/Yard dual-roll + Collect")
