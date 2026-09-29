--!strict
-- Pickup score pop: rises from lower screen, falls back, fades. Gradient from catalog.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local FxOverlay = require(script.Parent.FxOverlay)
local PickupScoreLogic = require(game:GetService("ReplicatedStorage").shared.util.PickupScoreLogic)
local ScoreGradientCatalog =
    require(game:GetService("ReplicatedStorage").shared.data.ScoreGradientCatalog)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)
local ViewportLayout = require(script.Parent.Parent.util.ViewportLayout)
local theme = require(script.Parent.Parent.theme)

local ScorePop = {}

-- UiFxOverlay uses IgnoreGuiInset — do not subtract GuiInset here.
local function toScale(abs: Vector2): UDim2
    local vp = ViewportLayout.getSize()
    return UDim2.fromScale(abs.X / math.max(1, vp.X), abs.Y / math.max(1, vp.Y))
end

local function applyGradient(label: TextLabel, gradientId: string)
    local def = ScoreGradientCatalog.get(gradientId) or ScoreGradientCatalog.at(1)
    local keypoints = table.create(#def.stops)
    for i, stop in def.stops do
        local c = stop.c
        keypoints[i] = ColorSequenceKeypoint.new(stop.t, Color3.fromRGB(c.r, c.g, c.b))
    end
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(keypoints)
    gradient.Rotation = 90
    gradient.Parent = label
end

function ScorePop.playFromPayload(payload: string)
    local kind, value = PickupScoreLogic.decode(payload)
    if kind == nil or value == nil then
        return
    end
    local gradientIndex = math.random(1, ScoreGradientCatalog.count())
    local spec = PickupScoreLogic.spec(kind, value, gradientIndex)
    ScorePop.play(spec)
end

function ScorePop.play(spec: PickupScoreLogic.PickupScoreSpec)
    local layer = FxOverlay.getLayer()
    local vp = ViewportLayout.getSize()
    local px = ViewportLayout.px
    local reduce = SettingsManager.isReduceMotion()

    local textSize = ViewportLayout.text(spec.textSize)
    if reduce then
        textSize = math.min(textSize, ViewportLayout.text(54))
    end

    local jitterX = (math.random() - 0.5) * math.min(px(240), vp.X * 0.22)
    local start = Vector2.new(vp.X * 0.5 + jitterX, vp.Y * 0.78)
    local peak = start
        - Vector2.new((math.random() - 0.5) * px(36), px(108) + math.random() * px(42))
    local fall = start
        + Vector2.new((math.random() - 0.5) * px(27), px(54) + math.random() * px(30))

    local label = Instance.new("TextLabel")
    label.Name = "ScorePop"
    label.BackgroundTransparency = 1
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = toScale(start)
    label.Size = UDim2.fromOffset(math.max(px(180), px(spec.textSize * 6)), px(spec.textSize + 24))
    label.Text = spec.text
    label.TextColor3 = theme.Colors.white
    label.Font = Enum.Font.FredokaOne
    label.TextSize = textSize
    label.TextStrokeColor3 = theme.Colors.outlineDark
    label.TextStrokeTransparency = 0
    label.ZIndex = 22
    label.Parent = layer

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Colors.outlineDark
    stroke.Thickness = if spec.isRare then px(8) else px(6)
    stroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Parent = label

    applyGradient(label, spec.gradientId)

    if reduce then
        Debris:AddItem(label, 0.45)
        return label
    end

    label.TextTransparency = 0
    stroke.Transparency = 0

    local upInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local downInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    local up = TweenService:Create(label, upInfo, { Position = toScale(peak) })
    up:Play()
    up.Completed:Once(function()
        if label.Parent == nil then
            return
        end
        TweenService:Create(label, downInfo, {
            Position = toScale(fall),
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        }):Play()
        TweenService:Create(stroke, downInfo, { Transparency = 1 }):Play()
    end)

    Debris:AddItem(label, 0.95)
    return label
end

return ScorePop
