--!strict
-- Looping ParticleEmitter (aura / channel). stop() → Enabled=false + cleanup.

local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type LoopConfig = {
	rate: number,
	color: Color3,
	lifetime: NumberRange?,
	speed: NumberRange?,
	size: NumberSequence?,
	lightEmission: number?,
}

export type LoopHandle = {
	anchor: BasePart,
	emitter: ParticleEmitter,
	setRate: (self: LoopHandle, rate: number) -> (),
	stop: (self: LoopHandle) -> (),
}

local LoopEmitterLayer = {}

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
	emitter.Color = ColorSequence.new(config.color, Color3.new(1, 1, 1))
	emitter.Size = config.size
		or NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.35, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		})
	emitter.Transparency = NumberSequence.new(0.2, 1)
	emitter.Lifetime = config.lifetime or NumberRange.new(0.55, 1.1)
	emitter.Speed = config.speed or NumberRange.new(0.8, 2.8)
	emitter.SpreadAngle = Vector2.new(70, 70)
	emitter.LightEmission = config.lightEmission or 0.75
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
	local handle = LoopEmitterLayer.start(parent, target.CFrame * offset, config, budget, distanceScale)
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
