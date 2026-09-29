--!strict
-- Full-bleed ScreenGui host for FTUE (IgnoreGuiInset).

local Players = game:GetService("Players")

local UiScreen = require(script.Parent.UiScreen)

local TutorialHost = {}

local _host: Frame? = nil
local _spotlight: Frame? = nil

local function screenGui(): ScreenGui
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    return UiScreen.ensure(playerGui, "GameTutorial", "tutorial")
end

function TutorialHost.get(): Frame
    local existing = _host
    if existing ~= nil and existing.Parent ~= nil then
        return existing
    end

    local gui = screenGui()
    local host = gui:FindFirstChild("Host")
    if host == nil or not host:IsA("Frame") then
        local frame = Instance.new("Frame")
        frame.Name = "Host"
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = false
        frame.ZIndex = 20
        frame.Parent = gui
        host = frame
    end

    _host = host :: Frame
    return _host :: Frame
end

-- Sibling of the React Host so spotlight instances are never reconciled.
function TutorialHost.spotlight(): Frame
    local existing = _spotlight
    if existing ~= nil and existing.Parent ~= nil then
        return existing
    end

    local gui = screenGui()
    local root = gui:FindFirstChild("Spotlight")
    if root == nil or not root:IsA("Frame") then
        local frame = Instance.new("Frame")
        frame.Name = "Spotlight"
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = false
        frame.ZIndex = 10
        frame.Active = false
        frame.Parent = gui
        root = frame
    end

    _spotlight = root :: Frame
    return _spotlight :: Frame
end

return TutorialHost
