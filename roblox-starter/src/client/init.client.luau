--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local ViewportLayout = require(script.ui.util.ViewportLayout)
local UiScreen = require(script.ui.util.UiScreen)
local ScreenOrientation = require(script.core.ScreenOrientation)
local VfxController = require(script.core.VfxController)
local VfxNetBridge = require(script.core.VfxNetBridge)

local RunService = game:GetService("RunService")
Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

ViewportLayout.start()
ScreenOrientation.apply()
VfxController.start()
VfxNetBridge.start()

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local GameRoot = require(script.ui.GameRoot)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = UiScreen.ensure(playerGui, "GameUI", "hud")
local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(GameRoot))

Logger.info("client", "boot complete")
