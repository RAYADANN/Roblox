--!strict
-- FTUE hint. Absolute design pixels via ViewportLayout, centered above the bottom edge.

local Players = game:GetService("Players")

local UiScreen = require(script.Parent.Parent.ui.util.UiScreen)
local ViewportLayout = require(script.Parent.Parent.ui.util.ViewportLayout)
local theme = require(script.Parent.Parent.ui.theme)

local TutorialHint = {}

local _label: TextLabel? = nil

local function ensure(): TextLabel
    local existing = _label
    if existing and existing.Parent then
        return existing
    end
    local player = Players.LocalPlayer
    local gui = UiScreen.ensure(player:WaitForChild("PlayerGui"), "TutorialHint", "tutorial")
    local label = Instance.new("TextLabel")
    label.Name = "Hint"
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.BackgroundColor3 = theme.Colors.bg3
    label.BackgroundTransparency = 0.15
    label.BorderSizePixel = 0
    label.Font = theme.Font.title
    label.TextColor3 = theme.Colors.textMain
    label.TextWrapped = true
    label.Visible = false
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = theme.Radius.chip
    corner.Parent = label
    _label = label
    return label
end

local function place(label: TextLabel)
    label.Size = UDim2.fromOffset(ViewportLayout.px(480), ViewportLayout.px(56))
    label.Position = UDim2.new(0.5, 0, 1, -ViewportLayout.px(36))
    label.TextSize = ViewportLayout.text(18)
end

function TutorialHint.show(text: string)
    local label = ensure()
    place(label)
    label.Text = text
    label.Visible = true
end

function TutorialHint.hide()
    if _label then
        _label.Visible = false
    end
end

return TutorialHint
