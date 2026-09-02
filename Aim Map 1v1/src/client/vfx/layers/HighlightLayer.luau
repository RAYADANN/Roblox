--!strict
-- Highlight pulse на модели/части (hit confirm без частиц).

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

export type HighlightConfig = {
    fillColor: Color3?,
    outlineColor: Color3?,
    duration: number?,
    fillTransparency: number?,
    outlineTransparency: number?,
}

local HighlightLayer = {}

function HighlightLayer.flash(target: Instance, config: HighlightConfig): Highlight?
    local host: Instance = target
    if target:IsA("BasePart") and target.Parent then
        host = target.Parent
    end

    local hl = Instance.new("Highlight")
    hl.Name = "VfxHighlight"
    hl.Adornee = if host:IsA("Model") then host else target
    hl.FillColor = config.fillColor or Color3.new(1, 1, 1)
    hl.OutlineColor = config.outlineColor or Color3.new(1, 1, 1)
    hl.FillTransparency = config.fillTransparency or 0.55
    hl.OutlineTransparency = config.outlineTransparency or 0.2
    hl.DepthMode = Enum.HighlightDepthMode.Occluded
    hl.Parent = host

    local duration = config.duration or 0.2
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(hl, info, {
        FillTransparency = 1,
        OutlineTransparency = 1,
    }):Play()
    Debris:AddItem(hl, duration + 0.05)
    return hl
end

return HighlightLayer
