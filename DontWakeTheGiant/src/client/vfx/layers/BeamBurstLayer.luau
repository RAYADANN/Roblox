--!strict
-- Короткий Beam burst (2 attachments). Только Medium+.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type BeamConfig = {
    length: number?,
    width0: number?,
    width1: number?,
    duration: number?,
    segments: number?,
}

local BeamBurstLayer = {}

function BeamBurstLayer.flash(
    parent: Instance,
    cframe: CFrame,
    color: Color3,
    config: BeamConfig,
    budget: QualityBudget
): Instance?
    if not budget.enableBeams then
        return nil
    end

    local length = config.length or 8
    local duration = config.duration or 0.22
    local root = Instance.new("Part")
    root.Name = "VfxBeamBurst"
    root.Anchored = true
    root.CanCollide = false
    root.CanQuery = false
    root.CanTouch = false
    root.Transparency = 1
    root.Size = Vector3.new(0.2, 0.2, 0.2)
    root.CFrame = cframe
    root.Parent = parent

    local a0 = Instance.new("Attachment")
    a0.Position = Vector3.new(0, 0, 0)
    a0.Parent = root
    local a1 = Instance.new("Attachment")
    a1.Position = Vector3.new(0, 0, -length)
    a1.Parent = root

    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
    beam.Width0 = config.width0 or 1.2
    beam.Width1 = config.width1 or 0.05
    beam.FaceCamera = true
    beam.LightEmission = 0.85
    beam.LightInfluence = 0
    beam.Segments = config.segments or 8
    beam.Transparency = NumberSequence.new(0.1, 1)
    beam.Parent = root

    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(beam, info, {
        Width0 = 0,
        Width1 = 0,
    }):Play()
    Debris:AddItem(root, duration + 0.05)
    return root
end

return BeamBurstLayer
