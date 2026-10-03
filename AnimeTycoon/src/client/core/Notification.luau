--!strict
-- Toast stack — TutorialHint-style large stroked text (colorable).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UiScreen = require(script.Parent.Parent.ui.util.UiScreen)
local theme = require(script.Parent.Parent.ui.theme)

export type ToastOptions = {
    text: string,
    color: Color3?,
    duration: number?,
}

local Notification = {}

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
        stack.Size = UDim2.new(1, 0, 0.45, 0)
        stack.Position = UDim2.new(0.5, 0, 0.06, 0)
        stack.AnchorPoint = Vector2.new(0.5, 0)
        stack.BackgroundTransparency = 1
        stack.Parent = gui
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = stack
        _container = stack
    end
    return _container :: Frame
end

function Notification.show(opts: ToastOptions)
    local stack = ensureGui()
    local label = Instance.new("TextLabel")
    label.Name = "Toast"
    label.Size = UDim2.new(0.92, 0, 0, 40)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.text
    label.TextColor3 = opts.color or theme.Colors.white
    label.Font = theme.Font.heavy
    label.TextSize = 36
    label.TextStrokeColor3 = theme.Colors.outlineDark
    label.TextStrokeTransparency = 0.15
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextTransparency = 1
    label.LayoutOrder = os.clock() * 1000
    label.Parent = stack

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Colors.outlineDark
    stroke.Thickness = 2
    stroke.Transparency = 1
    stroke.Parent = label

    TweenService:Create(label, TweenInfo.new(0.2), {
        TextTransparency = 0,
        TextStrokeTransparency = 0.15,
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.2), {
        Transparency = 0.2,
    }):Play()

    local duration = opts.duration or 2.5
    task.delay(duration, function()
        if label.Parent == nil then
            return
        end
        local out = TweenService:Create(label, TweenInfo.new(0.15), {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        })
        TweenService:Create(stroke, TweenInfo.new(0.15), {
            Transparency = 1,
        }):Play()
        out:Play()
        out.Completed:Wait()
        label:Destroy()
    end)
end

return Notification
