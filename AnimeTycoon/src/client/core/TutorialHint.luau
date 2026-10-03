--!strict
-- Large FTUE hint text (notification-style, no background panel).

local TweenService = game:GetService("TweenService")

local TutorialHost = require(script.Parent.Parent.ui.util.TutorialHost)
local theme = require(script.Parent.Parent.ui.theme)

local TutorialHint = {}

local _label: TextLabel? = nil

local function ensureLabel(): TextLabel
    local existing = _label
    if existing ~= nil and existing.Parent ~= nil then
        return existing
    end

    local host = TutorialHost.hint()
    local label = Instance.new("TextLabel")
    label.Name = "TutorialHintLabel"
    label.Size = UDim2.fromScale(0.92, 1)
    label.Position = UDim2.fromScale(0.5, 0)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = theme.Font.heavy
    label.TextSize = 36
    label.TextColor3 = theme.Colors.white
    label.TextStrokeColor3 = theme.Colors.outlineDark
    label.TextStrokeTransparency = 0.15
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.ZIndex = 31
    label.TextTransparency = 1
    label.Parent = host

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Colors.outlineDark
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = label

    _label = label
    return label
end

function TutorialHint.set(text: string?)
    local label = ensureLabel()
    if text == nil or text == "" then
        TweenService:Create(label, TweenInfo.new(0.15), {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        }):Play()
        return
    end
    label.Text = text
    label.TextTransparency = 1
    label.TextStrokeTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.2), {
        TextTransparency = 0,
        TextStrokeTransparency = 0.15,
    }):Play()
end

function TutorialHint.clear()
    TutorialHint.set(nil)
    local label = _label
    if label then
        label:Destroy()
        _label = nil
    end
end

return TutorialHint
