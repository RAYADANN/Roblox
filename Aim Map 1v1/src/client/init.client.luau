--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetPreloadManager = require(script.core.AssetPreloadManager)
local FirstPersonController = require(script.core.FirstPersonController)
local FootstepController = require(script.core.FootstepController)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local LookController = require(script.core.LookController)
local PracticeDummyHud = require(script.core.PracticeDummyHud)
local ScreenOrientation = require(script.core.ScreenOrientation)
local UiScreen = require(script.ui.util.UiScreen)
local VfxController = require(script.core.VfxController)
local VfxNetBridge = require(script.core.VfxNetBridge)
local ViewModelController = require(script.core.ViewModelController)
local WeaponAnimController = require(script.core.WeaponAnimController)
local WeaponController = require(script.core.WeaponController)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

-- Combat UI / hit VFX / SFX first so first shot isn't waiting on downloads.
AssetPreloadManager.preload()

ScreenOrientation.apply()
VfxController.start()
VfxNetBridge.start()
FirstPersonController.start()
LookController.start()
ViewModelController.start()
WeaponAnimController.start()
WeaponController.start()
FootstepController.start()
PracticeDummyHud.start()

local Packages = ReplicatedStorage:WaitForChild("Packages")
local GameRoot = require(script.ui.GameRoot)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = UiScreen.ensure(playerGui, "GameUI", "hud")
local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(GameRoot))

Logger.info("client", "boot complete (FPS duel)")
