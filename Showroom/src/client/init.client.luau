--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExhibitWorldRenderer = require(script.core.ExhibitWorldRenderer)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local MutationFx = require(script.core.MutationFx)
local PlotPromptBinder = require(script.core.PlotPromptBinder)
local ProximityUi = require(script.core.ProximityUi)
local ScreenOrientation = require(script.core.ScreenOrientation)
local UiScreen = require(script.ui.util.UiScreen)
local VfxController = require(script.core.VfxController)
local VfxNetBridge = require(script.core.VfxNetBridge)
local ViewportLayout = require(script.ui.util.ViewportLayout)

local RunService = game:GetService("RunService")
Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

ViewportLayout.start()
ScreenOrientation.apply()
MutationFx.preload()
VfxController.start()
VfxNetBridge.start()
ProximityUi.start()
ExhibitWorldRenderer.start()
PlotPromptBinder.start()

local Packages = ReplicatedStorage:WaitForChild("Packages")
local GameRoot = require(script.ui.GameRoot)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = UiScreen.ensure(playerGui, "GameUI", "hud")
local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(GameRoot))

Logger.info("client", "showroom boot complete")
