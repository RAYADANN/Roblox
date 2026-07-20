--!strict
-- Исполняет LayerStep[]. Расширяется через register(type, fn).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local QualityLogic = require(ReplicatedStorage.shared.vfx.QualityLogic)

local EmitterLayer = require(script.Parent.layers.EmitterLayer)
local LightLayer = require(script.Parent.layers.LightLayer)
local ShockwaveLayer = require(script.Parent.layers.ShockwaveLayer)
local BeamBurstLayer = require(script.Parent.layers.BeamBurstLayer)
local TrailLayer = require(script.Parent.layers.TrailLayer)
local LoopEmitterLayer = require(script.Parent.layers.LoopEmitterLayer)
local ProjectileLayer = require(script.Parent.layers.ProjectileLayer)
local HighlightLayer = require(script.Parent.layers.HighlightLayer)

export type LayerStep = LayerDef.LayerStep
export type QualityBudget = QualityLogic.QualityBudget

export type RunContext = {
	folder: Folder,
	cframe: CFrame,
	color: Color3,
	intensity: number,
	budget: QualityBudget,
	distanceScale: number,
	target: Instance?,
	from: CFrame?,
	to: CFrame?,
	cameraShake: (amplitude: number, duration: number, roughness: number?) -> (),
	cameraRumble: (amplitude: number, roughness: number?) -> (),
	screenFlash: (color: Color3, brightness: number, duration: number, blurSize: number?) -> (),
	--- Сборщик stop-коллбеков для Loop/Attached/Projectile
	trackStop: (stopFn: () -> ()) -> (),
	trackIntensity: (fn: (number) -> ()) -> (),
}

export type LayerFn = (ctx: RunContext, step: LayerStep) -> ()

local LayerRunner = {}

local registry: { [string]: LayerFn } = {}

function LayerRunner.register(layerType: string, fn: LayerFn)
	registry[layerType] = fn
end

function LayerRunner.runStep(ctx: RunContext, step: LayerStep)
	if not QualityLogic.allowsMinTier(step.minTier, ctx.budget) then
		return
	end
	local fn = registry[step.type]
	if not fn then
		warn(`[VFX.LayerRunner] unknown layer type: {step.type}`)
		return
	end
	fn(ctx, step)
end

-- Built-ins
LayerRunner.register("Emit", function(ctx, step)
	local count = QualityLogic.scaleEmit(step.count or 20, ctx.budget, ctx.distanceScale * ctx.intensity)
	EmitterLayer.burst(ctx.folder, ctx.cframe, ctx.color, {
		count = count,
		texture = step.texture,
		flipbookLayout = step.flipbookLayout,
		flipbookMode = step.flipbookMode,
		flipbookStartRandom = step.flipbookStartRandom,
		flipbookFpsMin = step.flipbookFpsMin,
		flipbookFpsMax = step.flipbookFpsMax,
	}, ctx.budget)
end)

LayerRunner.register("Light", function(ctx, step)
	LightLayer.pulse(ctx.folder, ctx.cframe, ctx.color, {
		range = (step.range or 14) * ctx.intensity,
		brightness = (step.brightness or 2.5) * ctx.intensity,
		duration = step.duration or 0.28,
	}, ctx.budget)
end)

LayerRunner.register("Shockwave", function(ctx, step)
	if not ctx.budget.enableShockwave then
		return
	end
	ShockwaveLayer.ring(ctx.folder, ctx.cframe, ctx.color, {
		endSize = (step.endSize or 10) * ctx.intensity,
		duration = step.duration or 0.35,
	})
end)

LayerRunner.register("Beam", function(ctx, step)
	BeamBurstLayer.flash(ctx.folder, ctx.cframe, ctx.color, {
		length = (step.length or 8) * ctx.intensity,
		width0 = step.width0,
		width1 = step.width1,
		duration = step.duration or 0.22,
	}, ctx.budget)
end)

LayerRunner.register("CameraShake", function(ctx, step)
	if not ctx.budget.enableCameraShake then
		return
	end
	ctx.cameraShake(
		(step.amplitude or 0.2) * ctx.intensity * ctx.distanceScale,
		step.duration or 0.16,
		step.roughness
	)
end)

LayerRunner.register("CameraRumble", function(ctx, step)
	if not ctx.budget.enableCameraShake then
		return
	end
	local amp = (step.rumble or step.amplitude or 0.06) * ctx.intensity
	ctx.cameraRumble(amp, step.roughness)
	ctx.trackStop(function()
		ctx.cameraRumble(0)
	end)
	ctx.trackIntensity(function(intensity)
		ctx.cameraRumble((step.rumble or 0.06) * intensity)
	end)
end)

LayerRunner.register("ScreenFlash", function(ctx, step)
	if not ctx.budget.enableScreenFX then
		return
	end
	ctx.screenFlash(
		ctx.color,
		(step.brightness or 0.12) * ctx.intensity,
		step.duration or 0.12,
		step.blurSize
	)
end)

LayerRunner.register("Trail", function(ctx, step)
	local anchor = Instance.new("Part")
	anchor.Name = "VfxTrailAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = ctx.cframe
	anchor.Parent = ctx.folder
	TrailLayer.attach(anchor, ctx.color, {
		duration = step.duration or 0.4,
		lifetime = 0.3,
		width0 = step.width0 or 1,
	}, ctx.budget)
	ctx.trackStop(function()
		if anchor.Parent then
			anchor:Destroy()
		end
	end)
end)

LayerRunner.register("LoopEmit", function(ctx, step)
	local handle = LoopEmitterLayer.start(ctx.folder, ctx.cframe, {
		rate = (step.rate or 20) * ctx.intensity,
		color = ctx.color,
	}, ctx.budget, ctx.distanceScale)
	if not handle then
		return
	end
	ctx.trackStop(function()
		handle:stop()
	end)
	ctx.trackIntensity(function(intensity)
		handle:setRate((step.rate or 20) * intensity)
	end)
end)

LayerRunner.register("AttachedEmit", function(ctx, step)
	local target = ctx.target
	if not target or not target:IsA("BasePart") then
		return
	end
	local handle = LoopEmitterLayer.startAttached(ctx.folder, target, CFrame.new(), {
		rate = (step.rate or 16) * ctx.intensity,
		color = ctx.color,
	}, ctx.budget, ctx.distanceScale)
	if not handle then
		return
	end
	ctx.trackStop(function()
		handle:stop()
	end)
	ctx.trackIntensity(function(intensity)
		handle:setRate((step.rate or 16) * intensity)
	end)
end)

LayerRunner.register("Projectile", function(ctx, step)
	local from = ctx.from or ctx.cframe
	local to = ctx.to
	if not to then
		return
	end
	local proj = ProjectileLayer.fire(ctx.folder, from, to, {
		color = ctx.color,
		speed = step.speed or 90,
		withTrail = ctx.budget.enableTrails,
		onArrive = function()
			local count = QualityLogic.scaleEmit(step.count or 24, ctx.budget, ctx.distanceScale)
			EmitterLayer.burst(ctx.folder, to, ctx.color, { count = count }, ctx.budget)
			if ctx.budget.enableShockwave then
				ShockwaveLayer.ring(ctx.folder, to, ctx.color, { endSize = step.endSize or 6 })
			end
		end,
	}, ctx.budget)
	ctx.trackStop(function()
		proj:stop()
	end)
end)

LayerRunner.register("Highlight", function(ctx, step)
	if not ctx.target then
		return
	end
	HighlightLayer.flash(ctx.target, {
		fillColor = ctx.color,
		outlineColor = Color3.new(1, 1, 1),
		duration = step.duration or 0.22,
		fillTransparency = step.fillTransparency,
		outlineTransparency = step.outlineTransparency,
	})
end)

return LayerRunner
