--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BasePromptGate = require(script.core.BasePromptGate)
local BoostOfferWorldVisual = require(script.core.BoostOfferWorldVisual)
local ConveyorVisual = require(script.core.ConveyorVisual)
local FloorUnlockCutscene = require(script.core.FloorUnlockCutscene)
local HandToolBinder = require(script.core.HandToolBinder)
local HeroReveal = require(script.ui.fx.HeroReveal)
local LimitedStandVisual = require(script.core.LimitedStandVisual)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local PadTierCutscene = require(script.core.PadTierCutscene)
local PadUnlockCutscene = require(script.core.PadUnlockCutscene)
local RampWorldRenderer = require(script.core.RampWorldRenderer)
local ScreenOrientation = require(script.core.ScreenOrientation)
local SellTableBoard = require(script.core.SellTableBoard)
local SoundManager = require(script.core.SoundManager)
local SpeedBoostVisual = require(script.core.SpeedBoostVisual)
local StandPromptBinder = require(script.core.StandPromptBinder)
local TutorialController = require(script.core.TutorialController)
local UiScreen = require(script.ui.util.UiScreen)
local VfxController = require(script.core.VfxController)
local VfxNetBridge = require(script.core.VfxNetBridge)
local ViewportLayout = require(script.ui.util.ViewportLayout)
local WorldBillboard = require(script.core.WorldBillboard)

local RunService = game:GetService("RunService")
Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

ViewportLayout.start()
ScreenOrientation.apply()
SoundManager.start()
VfxController.start()
VfxNetBridge.start()
StandPromptBinder.start()
RampWorldRenderer.start()
ConveyorVisual.start()
SellTableBoard.start()
SpeedBoostVisual.start()
WorldBillboard.applyMaxDistance()
LimitedStandVisual.start()
BoostOfferWorldVisual.start()
HandToolBinder.start()
HandToolBinder.setSetHandHandler(function(uid: string)
    local Zap = require(script.net.NetClient)
    task.spawn(function()
        Zap.SetHand.Call(uid)
    end)
end)
BasePromptGate.start()
HeroReveal.bindDebugHotkey()
PadUnlockCutscene.bindDebugHotkey()
PadTierCutscene.bindDebugHotkey()
FloorUnlockCutscene.bindDebugHotkey()
TutorialController.bindDebugHotkey(function()
    local Zap = require(script.net.NetClient)
    task.spawn(function()
        local result = Zap.ResetTutorial.Call()
        if not result.success then
            return
        end
        TutorialController.restartForDebug(function()
            task.spawn(function()
                Zap.CompleteTutorial.Call()
            end)
        end)
    end)
end)

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
