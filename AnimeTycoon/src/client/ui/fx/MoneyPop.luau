--!strict
-- Money text pop (как Tycoon ScorePop): +$amount вверх → вниз + fade.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Formatters = require(script.Parent.Parent.util.Formatters)
local FxOverlay = require(script.Parent.FxOverlay)
local ViewportLayout = require(script.Parent.Parent.util.ViewportLayout)
local theme = require(script.Parent.Parent.theme)

export type Options = {
    amount: number,
    --- Absolute screen px. Default: bottom-center with jitter (Tycoon).
    position: Vector2?,
    textSize: number?,
}

local MoneyPop = {}

local function isReduceMotion(): boolean
    local root = script.Parent.Parent.Parent
    local core = root:FindFirstChild("core")
    if core == nil then
        return false
    end
    local mod = core:FindFirstChild("SettingsManager")
    if mod == nil then
        return false
    end
    local ok, settings = pcall(require, mod)
    if ok and settings ~= nil and typeof(settings.isReduceMotion) == "function" then
        return settings.isReduceMotion() == true
    end
    return false
end

local function toLayerPos(abs: Vector2, layer: GuiObject): UDim2
    local origin = layer.AbsolutePosition
    return UDim2.fromOffset(abs.X - origin.X, abs.Y - origin.Y)
end

local function applyMoneyGradient(label: TextLabel)
    local gradient = Instance.new("UIGradient")
    -- как HUD money: яркий зелёный сверху → насыщенный вниз
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 255, 160)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 20)),
    })
    gradient.Rotation = 90
    gradient.Parent = label
end

function MoneyPop.play(opts: Options)
    local amount = opts.amount
    if amount <= 0 then
        return nil
    end

    local layer = FxOverlay.getLayer()
    local vp = ViewportLayout.getSize()
    local px = ViewportLayout.px
    local reduce = isReduceMotion()

    local designSize = opts.textSize or 72
    local textSize = ViewportLayout.text(designSize)
    if reduce then
        textSize = math.min(textSize, ViewportLayout.text(48))
    end

    local start: Vector2
    if opts.position ~= nil then
        start = opts.position
    else
        local jitterX = (math.random() - 0.5) * math.min(px(240), vp.X * 0.22)
        start = Vector2.new(vp.X * 0.5 + jitterX, vp.Y * 0.78)
    end
    local peak = start
        - Vector2.new((math.random() - 0.5) * px(36), px(108) + math.random() * px(42))
    local fall = start
        + Vector2.new((math.random() - 0.5) * px(27), px(54) + math.random() * px(30))

    local label = Instance.new("TextLabel")
    label.Name = "MoneyPop"
    label.BackgroundTransparency = 1
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = toLayerPos(start, layer)
    label.Size = UDim2.fromOffset(math.max(px(180), px(designSize * 6)), px(designSize + 24))
    label.Text = `+$` .. Formatters.shortNumber(amount)
    label.TextColor3 = theme.Colors.white
    label.Font = Enum.Font.FredokaOne
    label.TextSize = textSize
    label.TextStrokeColor3 = theme.Colors.outlineDark
    label.TextStrokeTransparency = 0
    label.ZIndex = 22
    label.Parent = layer

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Colors.outlineDark
    stroke.Thickness = px(6)
    stroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
    stroke.LineJoinMode = Enum.LineJoinMode.Bevel
    stroke.Parent = label

    applyMoneyGradient(label)

    if reduce then
        Debris:AddItem(label, 0.45)
        return label
    end

    label.TextTransparency = 0
    stroke.Transparency = 0

    local upInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local downInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    local up = TweenService:Create(label, upInfo, { Position = toLayerPos(peak, layer) })
    up:Play()
    up.Completed:Once(function()
        if label.Parent == nil then
            return
        end
        TweenService:Create(label, downInfo, {
            Position = toLayerPos(fall, layer),
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        }):Play()
        TweenService:Create(stroke, downInfo, { Transparency = 1 }):Play()
    end)

    Debris:AddItem(label, 0.95)
    return label
end

return MoneyPop
