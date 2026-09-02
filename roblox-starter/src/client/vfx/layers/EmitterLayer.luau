--!strict
-- Слой: burst ParticleEmitter на якоре. Emit() — контролируемый бюджет + пул.

local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)
local InstancePool = require(script.Parent.Parent.InstancePool)

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
	sizeScale: number?,
	drag: number?,
	--- Soft-LOD / intensity already applied by caller → set true to skip re-scale.
	preScaled: boolean?,
	distanceScale: number?,
	intensity: number?,
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

local _pool: InstancePool.InstancePool? = nil
local _outCount = 0

local function ensurePool(parent: Instance): InstancePool.InstancePool
	if _pool then
		return _pool
	end
	_pool = InstancePool.new({
		name = "VfxEmitterAnchor",
		maxSize = 96,
		parent = parent,
		factory = function()
			local anchor = Instance.new("Part")
			anchor.Name = "VfxEmitterAnchor"
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanQuery = false
			anchor.CanTouch = false
			anchor.Transparency = 1
			anchor.Size = Vector3.new(0.2, 0.2, 0.2)
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "Burst"
			emitter.Rate = 0
			emitter.Enabled = false
			emitter.Parent = anchor
			return anchor
		end,
		reset = function(inst)
			if inst:IsA("BasePart") then
				inst.CFrame = CFrame.new()
				local emitter = inst:FindFirstChild("Burst")
				if emitter and emitter:IsA("ParticleEmitter") then
					emitter.Enabled = false
					emitter.Rate = 0
					emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.None
				end
			end
		end,
	})
	_pool:prewarm(8)
	return _pool
end

local function applyDefaults(emitter: ParticleEmitter, config: EmitterConfig, color: Color3)
	local scale = config.sizeScale or 1
	emitter.Color = config.color or ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.Size = config.size
		or NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.15 * scale),
			NumberSequenceKeypoint.new(0.4, 0.8 * scale),
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
	emitter.Drag = config.drag or 0
	emitter.Rate = 0
	emitter.Enabled = false
	if config.texture then
		emitter.Texture = config.texture
	end
	if config.flipbookLayout then
		emitter.FlipbookLayout = FLIPBOOK_LAYOUTS[config.flipbookLayout] or Enum.ParticleFlipbookLayout.None
	else
		emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.None
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

function EmitterLayer.activeCount(): number
	return _outCount
end

function EmitterLayer.burst(
	parent: Instance,
	cframe: CFrame,
	color: Color3,
	config: EmitterConfig,
	budget: QualityBudget
): Instance
	local count = if config.preScaled
		then math.max(0, math.floor(config.count + 0.5))
		else QualityLogic.scaleEmit(
			config.count,
			budget,
			(config.distanceScale or 1) * (config.intensity or 1)
		)
	local pool = ensurePool(parent)
	local anchor = pool:take() :: BasePart
	anchor.Parent = parent
	anchor.CFrame = cframe
	_outCount += 1

	local emitter = anchor:FindFirstChild("Burst") :: ParticleEmitter
	if not emitter then
		emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Burst"
		emitter.Parent = anchor
	end
	applyDefaults(emitter, config, color)

	if count > 0 then
		emitter:Emit(count)
	end

	local lifetime = config.emitDuration or 1.2
	task.delay(lifetime, function()
		if anchor.Parent == nil then
			return
		end
		_outCount = math.max(0, _outCount - 1)
		pool:give(anchor)
	end)
	return anchor
end

return EmitterLayer
