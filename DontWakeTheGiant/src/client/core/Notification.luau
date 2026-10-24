--!strict
-- Toast stack (imperative API + React host).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiScreen = require(script.Parent.ui.util.UiScreen)
local theme = require(script.Parent.ui.theme)

export type ToastOptions = {
    text: string,
    color: Color3?,
    duration: number?,
}

local Notification = {}

local _gui: ScreenGui? = nil
local _container: Frame? = nil

local function ensureGui(): Frame
    if _container and _container.Parent then
        return _container
    end
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = UiScreen.ensure(playerGui, "Toasts", "toast")
    _container = gui:FindFirstChild("Stack") :: Frame?
    if not _container then
        local stack = Instance.new("Frame")
        stack.Name = "Stack"
        stack.Size = UDim2.new(1, 0, 0.4, 0)
        stack.Position = UDim2.new(0.5, 0, 0, 8)
        stack.AnchorPoint = Vector2.new(0.5, 0)
        stack.BackgroundTransparency = 1
        stack.Parent = gui
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = stack
        _container = stack
    end
    _gui = gui
    return _container :: Frame
end

function Notification.show(opts: ToastOptions)
    local stack = ensureGui()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.6, 0, 0, 44)
    frame.BackgroundColor3 = theme.Colors.bg3
    frame.BorderSizePixel = 0
    frame.LayoutOrder = os.clock() * 1000
    local corner = Instance.new("UICorner")
    corner.CornerRadius = theme.Radius.chip
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = opts.text
    label.TextColor3 = opts.color or theme.Colors.textMain
    label.Font = theme.Font.body
    label.TextSize = 14
    label.Parent = frame
    frame.Parent = stack

    local duration = opts.duration or 2.5
    task.delay(duration, function()
        frame:Destroy()
    end)
end

return Notification
