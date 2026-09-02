--!strict
-- Full-bleed ScreenGui host for inventory / settings (IgnoreGuiInset).

local Players = game:GetService("Players")

local UiScreen = require(script.Parent.UiScreen)

local ModalHost = {}

local _host: Frame? = nil

function ModalHost.get(): Frame
    local existing = _host
    if existing ~= nil and existing.Parent ~= nil then
        return existing
    end

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = UiScreen.ensure(playerGui, "GameModal", "modal")
    local host = gui:FindFirstChild("Host")
    if host == nil or not host:IsA("Frame") then
        local frame = Instance.new("Frame")
        frame.Name = "Host"
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = false
        frame.Parent = gui
        host = frame
    end

    _host = host :: Frame
    return _host :: Frame
end

return ModalHost
