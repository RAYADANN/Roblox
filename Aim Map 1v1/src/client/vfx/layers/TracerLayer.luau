--!strict
-- Bullet tracer: FaceCamera Beam ribbon muzzle → impact (Roblox-native streak).
-- Instant, tapers + fades in ~50–150ms. Skin color from PlayContext.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

export type TracerConfig = {
    width: number?,
    duration: number?,
    --- Studs to pull back from the hit point so the line doesn't stab into the surface.
    endShorten: number?,
}

local TracerLayer = {}

function TracerLayer.flash(
    parent: Instance,
    fromPos: Vector3,
    toPos: Vector3,
    color: Color3,
    config: TracerConfig?
): Instance?
    local shorten = if config and config.endShorten ~= nil then config.endShorten else 0.45
    local width = if config and config.width then config.width else 0.1
    local duration = if config and config.duration then config.duration else 0.1

    local delta = toPos - fromPos
    local fullDist = delta.Magnitude
    if fullDist < 0.75 then
        return nil
    end

    local dir = delta.Unit
    local length = math.max(fullDist - shorten, 0.75)
    local endPos = fromPos + dir * length

    local root = Instance.new("Part")
    root.Name = "VfxBulletTracer"
    root.Anchored = true
    root.CanCollide = false
    root.CanQuery = false
    root.CanTouch = false
    root.CastShadow = false
    root.Transparency = 1
    root.Size = Vector3.new(0.05, 0.05, 0.05)
    root.CFrame = CFrame.lookAt(fromPos, endPos)
    root.Parent = parent

    local a0 = Instance.new("Attachment")
    a0.Position = Vector3.zero
    a0.Parent = root
    local a1 = Instance.new("Attachment")
    a1.Position = Vector3.new(0, 0, -length)
    a1.Parent = root

    local tip = color:Lerp(Color3.new(1, 1, 1), 0.55)
    local beam = Instance.new("Beam")
    beam.Name = "Ribbon"
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Segments = 1
    beam.Width0 = width
    beam.Width1 = width * 0.35
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tip),
        ColorSequenceKeypoint.new(0.15, color),
        ColorSequenceKeypoint.new(1, color),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.08, 0.05),
        NumberSequenceKeypoint.new(1, 0.45),
    })
    beam.Parent = root

    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(beam, info, {
        Width0 = 0,
        Width1 = 0,
    }):Play()

    Debris:AddItem(root, duration + 0.05)
    return root
end

return TracerLayer
