--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local UI = ReplicatedStorage:WaitForChild("UI")
local App = require(UI.App)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UITemplates"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    (screenGui :: any).ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)
screenGui.Parent = playerGui

-- Scaling lives inside DesignRoot (React). Do not parent UIScale on ScreenGui —
-- createRoot reconciles ScreenGui children and would destroy it.

local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(App))
