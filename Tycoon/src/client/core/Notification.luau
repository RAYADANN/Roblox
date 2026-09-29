--!strict
-- Toast stack (imperative). Profile `toast`, image banner + pad-green success text.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local UiScreen = require(script.Parent.Parent.ui.util.UiScreen)
local ViewportLayout = require(script.Parent.Parent.ui.util.ViewportLayout)
local theme = require(script.Parent.Parent.ui.theme)

export type ToastOptions = {
    text: string,
    color: Color3?,
    duration: number?,
}

local MAX_STACK = 3
local DESIGN_W = 520
local DESIGN_H = 72

local Notification = {}

local _container: Frame? = nil
local _active: { Frame } = {}

local function ensureGui(): Frame
    if _container and _container.Parent then
        return _container
    end
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = UiScreen.ensure(playerGui, "Toasts", "toast")
    local stack = gui:FindFirstChild("Stack")
    if not (stack and stack:IsA("Frame")) then
        local frame = Instance.new("Frame")
        frame.Name = "Stack"
        frame.Size = UDim2.new(1, 0, 0.45, 0)
        frame.Position = UDim2.new(0.5, 0, 0, 10)
        frame.AnchorPoint = Vector2.new(0.5, 0)
        frame.BackgroundTransparency = 1
        frame.Active = false
        frame.Parent = gui
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, ViewportLayout.gap(8))
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame
        stack = frame
    end
    _container = stack :: Frame
    return _container
end

local function pruneStack()
    while #_active > MAX_STACK do
        local oldest = table.remove(_active, 1)
        if oldest then
            oldest:Destroy()
        end
    end
end

function Notification.show(opts: ToastOptions)
    local stack = ensureGui()
    local bgImage =
        IconCatalog.resolveImage(IconCatalog.NotificationBackground, "NotificationBackground")
    local color = opts.color or theme.Colors.padGreen
    local duration = opts.duration or 2.5

    local frame = Instance.new("Frame")
    frame.Name = "Toast"
    frame.Size = UDim2.fromOffset(ViewportLayout.px(DESIGN_W), ViewportLayout.px(DESIGN_H))
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.LayoutOrder = math.floor(os.clock() * 1000)
    frame.Parent = stack

    local bg = Instance.new("ImageLabel")
    bg.Name = "Background"
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Image = bgImage
    bg.ScaleType = Enum.ScaleType.Stretch
    bg.Active = false
    bg.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -ViewportLayout.px(28), 1, 0)
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.BackgroundTransparency = 1
    label.Text = opts.text
    label.TextColor3 = color
    label.TextStrokeColor3 = theme.Colors.black
    label.TextStrokeTransparency = 0.35
    label.Font = theme.Font.heavy
    label.TextSize = ViewportLayout.text(22)
    label.TextWrapped = true
    label.Active = false
    label.ZIndex = 2
    label.Parent = frame

    bg.ImageTransparency = 1
    label.TextTransparency = 1
    local fadeIn = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(bg, fadeIn, { ImageTransparency = 0 }):Play()
    TweenService:Create(label, fadeIn, { TextTransparency = 0 }):Play()

    table.insert(_active, frame)
    pruneStack()

    task.delay(duration, function()
        if frame.Parent == nil then
            return
        end
        local fadeOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local t1 = TweenService:Create(bg, fadeOut, { ImageTransparency = 1 })
        local t2 = TweenService:Create(label, fadeOut, { TextTransparency = 1 })
        t1:Play()
        t2:Play()
        t2.Completed:Wait()
        local idx = table.find(_active, frame)
        if idx then
            table.remove(_active, idx)
        end
        frame:Destroy()
    end)
end

return Notification
