--!strict
-- Host layer for imperative UI FX.
-- Preferred: HudShell FxHost (ZIndex below money, above windows).
-- Fallback: same ScreenGui as HUD / PlayerGui (Play & Hoarcekat).

local Players = game:GetService("Players")

local HudMoneyAnchor = require(script.Parent.HudMoneyAnchor)
local UiScreen = require(script.Parent.Parent.util.UiScreen)

local FxOverlay = {}

local _gui: ScreenGui? = nil
local _layer: Frame? = nil
local _preferredHost: GuiObject? = nil

--- HudShell registers a Frame under the React tree so FX ZIndex sits below money.
function FxOverlay.setHost(host: GuiObject?)
    _preferredHost = host
    if host == nil then
        _layer = nil
        _gui = nil
    end
end

local function resolveHost(): Instance
    local preferred = _preferredHost
    if preferred ~= nil and preferred.Parent ~= nil then
        return preferred
    end
    local bound = HudMoneyAnchor.getBound()
    if bound ~= nil then
        local screen = bound:FindFirstAncestorOfClass("ScreenGui")
        if screen ~= nil then
            return screen
        end
        local collector = bound:FindFirstAncestorWhichIsA("LayerCollector")
        if collector ~= nil then
            return collector
        end
        if bound.Parent ~= nil then
            return bound.Parent
        end
    end
    local player = Players.LocalPlayer
    if player == nil then
        error("[FxOverlay] LocalPlayer missing")
    end
    return player:WaitForChild("PlayerGui")
end

local function makeLayer(name: string, parent: Instance): Frame
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Frame") then
        existing.ZIndex = 1
        existing.ClipsDescendants = false
        return existing
    end
    local layer = Instance.new("Frame")
    layer.Name = name
    layer.BackgroundTransparency = 1
    layer.Size = UDim2.fromScale(1, 1)
    layer.Position = UDim2.fromScale(0, 0)
    layer.BorderSizePixel = 0
    layer.ClipsDescendants = false
    layer.ZIndex = 1
    layer.Parent = parent
    return layer
end

local function ensureLayer(host: Instance): Frame
    if host:IsA("ScreenGui") then
        return makeLayer("UiFxLayer", host)
    end
    if host:IsA("PlayerGui") or host:IsA("LayerCollector") then
        local gui = UiScreen.ensure(host, "UiFxOverlay", "fx")
        return makeLayer("Layer", gui)
    end
    -- Preferred HudShell FxHost (or any Frame)
    return makeLayer("UiFxLayer", host)
end

function FxOverlay.getLayer(): Frame
    local host = resolveHost()
    if _layer ~= nil and _layer.Parent ~= nil then
        local currentHost = _layer.Parent
        if currentHost == host then
            return _layer
        end
    end

    local layer = ensureLayer(host)
    _layer = layer
    if host:IsA("ScreenGui") then
        _gui = host
    elseif layer.Parent and layer.Parent:IsA("ScreenGui") then
        _gui = layer.Parent
    else
        _gui = nil
    end
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
