--!strict
-- UI FX primitives. Copy/skin per game — not a second VfxEngine.
-- See docs/VFX_ENGINE.md «UI FX» and .cursor/rules/fx.mdc.

local CoinRain = require(script.Parent.CoinRain)
local Confetti = require(script.Parent.Confetti)
local FloatText = require(script.Parent.FloatText)
local FlyBurst = require(script.Parent.FlyBurst)
local FxOverlay = require(script.Parent.FxOverlay)
local MoneyGainFx = require(script.Parent.MoneyGainFx)
local MoneyPop = require(script.Parent.MoneyPop)

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local FxKit = {}

FxKit.overlay = FxOverlay
FxKit.floatText = FloatText
FxKit.flyBurst = FlyBurst
FxKit.coinRain = CoinRain
FxKit.confetti = Confetti
FxKit.moneyGain = MoneyGainFx
FxKit.moneyPop = MoneyPop

function FxKit.shockwave(parent: Instance, color: Color3, size: number, duration: number?)
    local dur = duration or 0.4
    local ring = Instance.new("Frame")
    ring.Name = "Shockwave"
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Size = UDim2.fromOffset(8, 8)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 10
    ring.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 3
    stroke.Transparency = 0.2
    stroke.Parent = ring

    local info = TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(ring, info, { Size = UDim2.fromOffset(size, size) }):Play()
    TweenService:Create(stroke, info, { Transparency = 1 }):Play()
    Debris:AddItem(ring, dur + 0.1)
end

return FxKit
