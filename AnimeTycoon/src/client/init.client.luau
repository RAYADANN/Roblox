--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConveyorVisual = require(script.core.ConveyorVisual)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local RampWorldRenderer = require(script.core.RampWorldRenderer)
local ScreenOrientation = require(script.core.ScreenOrientation)
local StandPromptBinder = require(script.core.StandPromptBinder)
local UiScreen = require(script.ui.util.UiScreen)
local VfxController = require(script.core.VfxController)
local VfxNetBridge = require(script.core.VfxNetBridge)
local ViewportLayout = require(script.ui.util.ViewportLayout)

local RunService = game:GetService("RunService")
Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

ViewportLayout.start()
ScreenOrientation.apply()
VfxController.start()
VfxNetBridge.start()
StandPromptBinder.start()
RampWorldRenderer.start()
ConveyorVisual.start()

local Packages = ReplicatedStorage:WaitForChild("Packages")
local GameRoot = require(script.ui.GameRoot)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local designGui = playerGui:FindFirstChild("ScreenGui")
if designGui ~= nil and designGui:IsA("ScreenGui") then
    designGui.Enabled = false
end

local screenGui = UiScreen.ensure(playerGui, "GameUI", "hud")
local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(GameRoot))

Logger.info("client", "boot complete")
