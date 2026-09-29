--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local PickupScoreBridge = require(script.core.PickupScoreBridge)
local ScreenOrientation = require(script.core.ScreenOrientation)
local SoundManager = require(script.core.SoundManager)
local UiScreen = require(script.ui.util.UiScreen)
local VfxController = require(script.core.VfxController)
local VfxNetBridge = require(script.core.VfxNetBridge)
local Zap = require(script.net.NetClient)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

ScreenOrientation.apply()
SoundManager.start()
VfxController.start()
VfxNetBridge.start()
PickupScoreBridge.start()

Zap.PromptGamePass.On(function(gamepassId)
    local player = Players.LocalPlayer
    if player == nil or typeof(gamepassId) ~= "number" or gamepassId <= 0 then
        return
    end
    MarketplaceService:PromptGamePassPurchase(player, gamepassId)
end)

local Packages = ReplicatedStorage:WaitForChild("Packages")
local GameRoot = require(script.ui.GameRoot)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local starterHud = StarterGui:FindFirstChild("HUD")
if starterHud and starterHud:IsA("ScreenGui") then
    starterHud.Enabled = false
end

local function hideLegacyHud()
    local legacyHud = playerGui:FindFirstChild("HUD")
    if legacyHud and legacyHud:IsA("ScreenGui") then
        legacyHud.Enabled = false
    end
end
hideLegacyHud()
player.CharacterAdded:Connect(hideLegacyHud)

local screenGui = UiScreen.ensure(playerGui, "GameUI", "hud")
local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(GameRoot))

Logger.info("client", "boot complete")
