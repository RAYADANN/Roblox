--!strict
-- Host ScreenGui for imperative UI FX (above HUD, below loading).

local Players = game:GetService("Players")

local UiScreen = require(script.Parent.Parent.util.UiScreen)

local FxOverlay = {}

local _gui: ScreenGui? = nil
local _layer: Frame? = nil

function FxOverlay.getLayer(): Frame
    if _layer and _layer.Parent then
        return _layer
    end
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = UiScreen.ensure(playerGui, "UiFxOverlay", "fx")
    local layer = gui:FindFirstChild("Layer") :: Frame?
    if not layer then
        layer = Instance.new("Frame")
        layer.Name = "Layer"
        layer.BackgroundTransparency = 1
        layer.Size = UDim2.fromScale(1, 1)
        layer.BorderSizePixel = 0
        layer.ClipsDescendants = false
        layer.Parent = gui
    end
    _gui = gui
    _layer = layer
    return layer
end

function FxOverlay.clear()
    local layer = _layer
    if not layer then
        return
    end
    for _, child in layer:GetChildren() do
        child:Destroy()
    end
end

return FxOverlay
