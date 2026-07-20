--!strict
-- Слой: burst ParticleEmitter на якоре. Emit() — контролируемый бюджет.

local Debris = game:GetService("Debris")
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type EmitterConfig = {
	color: ColorSequence?,
	size: NumberSequence?,
	transparency: NumberSequence?,
	lifetime: NumberRange?,
	speed: NumberRange?,
	spreadAngle: Vector2?,
	rotSpeed: NumberRange?,
	lightEmission: number?,
	lightInfluence: number?,
	texture: string?,
	flipbookLayout: string?,
	flipbookMode: string?,
	flipbookStartRandom: boolean?,
	flipbookFpsMin: number?,
	flipbookFpsMax: number?,
	count: number,
	emitDuration: number?,
}

local EmitterLayer = {}

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

local function applyDefaults(emitter: ParticleEmitter, config: EmitterConfig, color: Color3)
	emitter.Color = config.color or ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.Size = config.size
		or NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.15),
			NumberSequenceKeypoint.new(0.4, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		})
	emitter.Transparency = config.transparency
		or NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
	emitter.Lifetime = config.lifetime or NumberRange.new(0.35, 0.7)
	emitter.Speed = config.speed or NumberRange.new(5, 15)
	emitter.SpreadAngle = config.spreadAngle or Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = config.rotSpeed or NumberRange.new(-90, 90)
	emitter.LightEmission = config.lightEmission or 0.6
	emitter.LightInfluence = config.lightInfluence or 0.2
	emitter.Rate = 0
	emitter.Enabled = false
	if config.texture then
		emitter.Texture = config.texture
	end
	if config.flipbookLayout then
		emitter.FlipbookLayout = FLIPBOOK_LAYOUTS[config.flipbookLayout] or Enum.ParticleFlipbookLayout.None
	end
	if config.flipbookMode then
		emitter.FlipbookMode = FLIPBOOK_MODES[config.flipbookMode] or Enum.ParticleFlipbookMode.Loop
	end
	if config.flipbookStartRandom ~= nil then
		emitter.FlipbookStartRandom = config.flipbookStartRandom
	end
	if config.flipbookFpsMin or config.flipbookFpsMax then
		local minFps = config.flipbookFpsMin or config.flipbookFpsMax or 12
		local maxFps = config.flipbookFpsMax or minFps
		emitter.FlipbookFramerate = NumberRange.new(minFps, maxFps)
	end
end

function EmitterLayer.burst(
	parent: Instance,
	cframe: CFrame,
	color: Color3,
	config: EmitterConfig,
	budget: QualityBudget
): Instance
	local count = QualityLogic.scaleEmit(config.count, budget)
	local anchor = Instance.new("Part")
	anchor.Name = "VfxEmitterAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = cframe
	anchor.Parent = parent

	local emitter = Instance.new("ParticleEmitter")
	applyDefaults(emitter, config, color)
	emitter.Parent = anchor

	if count > 0 then
		emitter:Emit(count)
	end

	local lifetime = config.emitDuration or 1.2
	Debris:AddItem(anchor, lifetime)
	return anchor
end

return EmitterLayer
