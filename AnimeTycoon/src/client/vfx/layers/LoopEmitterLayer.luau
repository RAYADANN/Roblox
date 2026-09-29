--!strict
-- Looping ParticleEmitter (aura / channel / ambient smoke). stop() → Enabled=false + cleanup.

local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type LoopConfig = {
    rate: number,
    color: Color3,
    colorSequence: ColorSequence?,
    lifetime: NumberRange?,
    speed: NumberRange?,
    size: NumberSequence?,
    transparency: NumberSequence?,
    spreadAngle: Vector2?,
    rotation: NumberRange?,
    rotSpeed: NumberRange?,
    lightEmission: number?,
    lightInfluence: number?,
    drag: number?,
    acceleration: Vector3?,
    zOffset: number?,
    texture: string?,
    flipbookLayout: string?,
    flipbookMode: string?,
    flipbookStartRandom: boolean?,
    flipbookFpsMin: number?,
    flipbookFpsMax: number?,
    emissionDirection: Enum.NormalId?,
    lockedToPart: boolean?,
}

export type LoopHandle = {
    anchor: BasePart,
    emitter: ParticleEmitter,
    setRate: (self: LoopHandle, rate: number) -> (),
    stop: (self: LoopHandle) -> (),
}

local FLIPBOOK_LAYOUTS: { [string]: Enum.ParticleFlipbookLayout } = {
    None = Enum.ParticleFlipbookLayout.None,
    Grid2x2 = Enum.ParticleFlipbookLayout.Grid2x2,
    Grid4x4 = Enum.ParticleFlipbookLayout.Grid4x4,
    Grid8x8 = Enum.ParticleFlipbookLayout.Grid8x8,
}

local FLIPBOOK_MODES: { [string]: Enum.ParticleFlipbookMode } = {
    Loop = Enum.ParticleFlipbookMode.Loop,
    OneShot = Enum.ParticleFlipbookMode.OneShot,
    PingPong = Enum.ParticleFlipbookMode.PingPong,
    Random = Enum.ParticleFlipbookMode.Random,
}

local LoopEmitterLayer = {}

local function applyConfig(emitter: ParticleEmitter, config: LoopConfig)
    emitter.Color = config.colorSequence
        or ColorSequence.new(config.color, Color3.fromRGB(180, 185, 195))
    emitter.Size = config.size
        or NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9),
            NumberSequenceKeypoint.new(0.35, 0.7),
            NumberSequenceKeypoint.new(1, 0),
        })
    emitter.Transparency = config.transparency or NumberSequence.new(0.2, 1)
    emitter.Lifetime = config.lifetime or NumberRange.new(0.55, 1.1)
    emitter.Speed = config.speed or NumberRange.new(0.8, 2.8)
    emitter.SpreadAngle = config.spreadAngle or Vector2.new(70, 70)
    emitter.Rotation = config.rotation or NumberRange.new(0, 360)
    emitter.RotSpeed = config.rotSpeed or NumberRange.new(-40, 40)
    emitter.LightEmission = config.lightEmission or 0.75
    emitter.LightInfluence = config.lightInfluence or 0.35
    emitter.Drag = config.drag or 0
    emitter.Acceleration = config.acceleration or Vector3.zero
    emitter.ZOffset = config.zOffset or 0
    emitter.Orientation = Enum.ParticleOrientation.FacingCamera
    emitter.EmissionDirection = config.emissionDirection or Enum.NormalId.Top
    emitter.LockedToPart = if config.lockedToPart == nil then false else config.lockedToPart

    if config.texture then
        emitter.Texture = config.texture
    end
    if config.flipbookLayout then
        emitter.FlipbookLayout = FLIPBOOK_LAYOUTS[config.flipbookLayout]
            or Enum.ParticleFlipbookLayout.None
    else
        emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.None
    end
    if config.flipbookMode then
        emitter.FlipbookMode = FLIPBOOK_MODES[config.flipbookMode] or Enum.ParticleFlipbookMode.Loop
    end
    if config.flipbookStartRandom ~= nil then
        emitter.FlipbookStartRandom = config.flipbookStartRandom
    else
        emitter.FlipbookStartRandom = true
    end
    if config.flipbookFpsMin or config.flipbookFpsMax then
        local minFps = config.flipbookFpsMin or config.flipbookFpsMax or 10
        local maxFps = config.flipbookFpsMax or minFps
        emitter.FlipbookFramerate = NumberRange.new(minFps, maxFps)
    end
end

function LoopEmitterLayer.start(
    parent: Instance,
    cframe: CFrame,
    config: LoopConfig,
    budget: QualityBudget,
    distanceScale: number
): LoopHandle?
    if not budget.enableLoops then
        return nil
    end

    local anchor = Instance.new("Part")
    anchor.Name = "VfxLoopAnchor"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.25, 0.25, 0.25)
    anchor.CFrame = cframe
    anchor.Parent = parent

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Loop"
    applyConfig(emitter, config)
    emitter.Rate = math.max(0, config.rate * budget.particleScale * distanceScale)
    emitter.Enabled = emitter.Rate > 0
    emitter.Parent = anchor

    local handle: LoopHandle
    handle = {
        anchor = anchor,
        emitter = emitter,
        setRate = function(_, rate: number)
            emitter.Rate = math.max(0, rate * budget.particleScale * distanceScale)
            emitter.Enabled = emitter.Rate > 0
        end,
        stop = function(_)
            emitter.Enabled = false
            emitter.Rate = 0
            anchor:Destroy()
        end,
    }
    return handle
end

--- Attached: якорь следует за BasePart (не Weld — дешевле для FX).
function LoopEmitterLayer.startAttached(
    parent: Instance,
    target: BasePart,
    offset: CFrame,
    config: LoopConfig,
    budget: QualityBudget,
    distanceScale: number
): LoopHandle?
    local handle =
        LoopEmitterLayer.start(parent, target.CFrame * offset, config, budget, distanceScale)
    if not handle then
        return nil
    end
    handle.anchor.Anchored = false
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target
    weld.Part1 = handle.anchor
    weld.Parent = handle.anchor
    handle.anchor.CFrame = target.CFrame * offset
    return handle
end

return LoopEmitterLayer
