--!strict
-- Клиентский VFX-движок v2: kinds, handles, LayerRunner, pluggable camera.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages.Trove)
local Types = require(ReplicatedStorage.shared.vfx.Types)
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local QualityLogic = require(ReplicatedStorage.shared.vfx.QualityLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)

local QualityProbe = require(script.Parent.QualityProbe)
local BudgetGate = require(script.Parent.BudgetGate)
local Timeline = require(script.Parent.Timeline)
local ScreenFX = require(script.Parent.ScreenFX)
local EffectHandleMod = require(script.Parent.EffectHandle)
local LayerRunner = require(script.Parent.LayerRunner)
local PlaySupport = require(script.Parent.PlaySupport)
local Camera = require(script.Parent.camera)
local EmitterLayer = require(script.Parent.layers.EmitterLayer)

export type FxPriority = Types.FxPriority
export type EffectKind = Types.EffectKind
export type EffectDef = LayerDef.EffectDef
export type QualityBudget = QualityLogic.QualityBudget
export type EffectHandle = EffectHandleMod.EffectHandle
export type CameraMode = Camera.CameraMode
export type CameraDriver = Camera.CameraDriver

export type PlayContext = {
	cframe: CFrame?,
	from: CFrame?,
	to: CFrame?,
	target: Instance?,
	color: Color3?,
	intensity: number?,
	priority: FxPriority?,
	origin: Vector3?,
	soundId: string?,
	payload: { [string]: unknown }?,
}

export type Deps = {
	isReduceMotion: (() -> boolean)?,
	playSound: ((soundId: string, pitch: number?) -> ())?,
	playHaptic: ((profile: string?, strength: number?) -> ())?,
	worldFolder: Folder?,
	cameraMode: CameraMode?,
	cameraDriver: CameraDriver?,
	onShakeOffset: ((Vector3) -> ())?,
}

export type VfxEngine = {
	register: (self: VfxEngine, def: EffectDef) -> (),
	registerLayer: (self: VfxEngine, layerType: string, fn: LayerRunner.LayerFn) -> (),
	play: (self: VfxEngine, effectId: string, ctx: PlayContext) -> EffectHandle?,
	stopAll: (self: VfxEngine) -> (),
	getBudget: (self: VfxEngine) -> QualityBudget,
	getStats: (self: VfxEngine) -> {
		active: number,
		tier: string,
		fps: number,
		emitters: number,
		thermal: number,
		dropped: number,
	},
	setTierOverride: (self: VfxEngine, tier: Types.QualityTier?) -> (),
	getCameraDriver: (self: VfxEngine) -> CameraDriver,
	setCameraDriver: (self: VfxEngine, driver: CameraDriver) -> (),
	getPreferredCameraMode: (self: VfxEngine) -> CameraMode,
	getWorldFolder: (self: VfxEngine) -> Folder,
	destroy: (self: VfxEngine) -> (),
}

local VfxEngine = {}
VfxEngine.__index = VfxEngine

function VfxEngine.new(deps: Deps?): VfxEngine
	local trove = Trove.new()
	local folder = if deps and deps.worldFolder
		then deps.worldFolder
		else PlaySupport.ensureFolder(Workspace, "VfxWorld")

	local probe = QualityProbe.new({
		isReduceMotion = if deps then deps.isReduceMotion else nil,
	})
	trove:Add(function()
		probe:destroy()
	end)

	local gate = BudgetGate.new()
	trove:Add(function()
		gate:destroy()
	end)

	local preferredMode: CameraMode = if deps and deps.cameraMode then deps.cameraMode else "HumanoidOffset"
	local cameraDriver = Camera.resolve({
		mode = preferredMode,
		driver = if deps then deps.cameraDriver else nil,
		onShakeOffset = if deps then deps.onShakeOffset else nil,
	})
	trove:Add(function()
		cameraDriver:destroy()
	end)

	local screenFX = ScreenFX.new()
	trove:Add(function()
		screenFX:destroy()
	end)

	local self = setmetatable({
		_trove = trove,
		_folder = folder,
		_probe = probe,
		_gate = gate,
		_camera = cameraDriver,
		_preferredCameraMode = preferredMode,
		_onShakeOffset = if deps then deps.onShakeOffset else nil,
		_isReduceMotion = if deps then deps.isReduceMotion else nil,
		_reduceMotionCamera = false,
		_screenFX = screenFX,
		_defs = {} :: { [string]: EffectDef },
		_active = {} :: { EffectHandle },
		_playSound = if deps then deps.playSound else nil,
		_playHaptic = if deps then deps.playHaptic else nil,
		_destroyed = false,
	}, VfxEngine)

	return (self :: any) :: VfxEngine
end

function VfxEngine:register(def: EffectDef)
	self._defs[def.id] = def
end

function VfxEngine:registerLayer(layerType: string, fn: LayerRunner.LayerFn)
	LayerRunner.register(layerType, fn)
end

function VfxEngine:getBudget(): QualityBudget
	return self._probe:getBudget()
end

function VfxEngine:setTierOverride(tier: Types.QualityTier?)
	self._probe:setTierOverride(tier)
end

function VfxEngine:getStats()
	local budget = self:getBudget()
	local fps = self._probe:getFps()
	return {
		active = self._gate:activeCount(),
		tier = budget.tier,
		fps = math.floor(fps + 0.5),
		emitters = EmitterLayer.activeCount(),
		thermal = QualityLogic.thermalScale(fps),
		dropped = self._gate:droppedCount(),
	}
end

function VfxEngine:getPreferredCameraMode(): CameraMode
	return self._preferredCameraMode
end

function VfxEngine:getWorldFolder(): Folder
	return self._folder
end

function VfxEngine:getCameraDriver(): CameraDriver
	return self._camera
end

function VfxEngine:setCameraDriver(driver: CameraDriver)
	self._camera:destroy()
	self._camera = driver
end

local function syncReduceMotionCamera(self: any)
	local reduce = false
	if self._isReduceMotion then
		reduce = self._isReduceMotion()
	end
	if reduce and not self._reduceMotionCamera then
		self._reduceMotionCamera = true
		self._camera:destroy()
		self._camera = Camera.resolve({ mode = "Noop" })
	elseif not reduce and self._reduceMotionCamera then
		self._reduceMotionCamera = false
		self._camera:destroy()
		self._camera = Camera.resolve({
			mode = self._preferredCameraMode,
			onShakeOffset = self._onShakeOffset,
		})
	end
end

function VfxEngine:stopAll()
	for _, handle in table.clone(self._active) do
		handle:stop()
	end
end

function VfxEngine:play(effectId: string, ctx: PlayContext): EffectHandle?
	if self._destroyed then
		return nil
	end

	syncReduceMotionCamera(self)

	local def = self._defs[effectId]
	if not def then
		Logger.warn("VfxEngine", `unknown effect {effectId}`)
		return nil
	end

	local priority = ctx.priority or def.priority
	local kind = def.kind
	local budget = self:getBudget()

	if not QualityLogic.allowsKind(kind, budget) then
		return nil
	end
	if not QualityLogic.allowsPriority(priority, budget) and priority ~= "Critical" then
		return nil
	end

	local origin = PlaySupport.resolveOrigin(ctx, kind)
	local camera = Workspace.CurrentCamera
	local maxDist = def.maxDistance or budget.maxDistance
	local distance = 0
	if camera and kind ~= "Screen" then
		distance = (origin - camera.CFrame.Position).Magnitude
		if distance > maxDist then
			return nil
		end
	end
	local distScale = if kind == "Screen" then 1 else QualityLogic.distanceScale(distance, maxDist)

	if not self._gate:tryAcquire(priority, budget) then
		return nil
	end

	local stopFns: { () -> () } = {}
	local intensityFns: { (number) -> () } = {}
	local timeline = Timeline.new()
	local released = false
	local listed = false

	local function releaseGate()
		if released then
			return
		end
		released = true
		if not self._destroyed then
			self._gate:release()
		end
	end

	local function untrack(handle: EffectHandle)
		if not listed then
			return
		end
		listed = false
		local i = table.find(self._active, handle)
		if i then
			table.remove(self._active, i)
		end
	end

	local handle: EffectHandle
	handle = EffectHandleMod.new({
		id = effectId,
		kind = kind,
		intensity = ctx.intensity or 1,
		onStop = function()
			timeline:destroy()
			for _, fn in stopFns do
				pcall(fn)
			end
			table.clear(stopFns)
			releaseGate()
			untrack(handle)
		end,
		onIntensity = function(value)
			for _, fn in intensityFns do
				pcall(fn, value)
			end
		end,
	})
	table.insert(self._active, handle)
	listed = true

	local runCtx: LayerRunner.RunContext = {
		folder = self._folder,
		cframe = PlaySupport.resolveCFrame(ctx),
		color = ctx.color or Color3.fromRGB(160, 220, 255),
		intensity = handle:getIntensity(),
		budget = budget,
		distanceScale = distScale,
		target = ctx.target,
		from = ctx.from,
		to = ctx.to,
		cameraShake = function(amp, dur, rough)
			self._camera:shake(amp, dur, rough)
		end,
		cameraRumble = function(amp, rough)
			self._camera:setRumble(amp, rough)
		end,
		screenFlash = function(c, b, d, blur)
			self._screenFX:flash(c, b, d, blur)
		end,
		playSound = self._playSound,
		playHaptic = self._playHaptic,
		trackStop = function(fn)
			table.insert(stopFns, fn)
		end,
		trackIntensity = function(fn)
			table.insert(intensityFns, fn)
		end,
	}

	local ok, err = pcall(function()
		for _, step in def.layers do
			local stepCopy = step
			timeline:at(step.at, function()
				if not handle:isPlaying() then
					return
				end
				runCtx.intensity = handle:getIntensity()
				LayerRunner.runStep(runCtx, stepCopy)
			end)
		end
		timeline:start()
		if ctx.soundId and self._playSound then
			self._playSound(ctx.soundId)
		end
	end)

	if PlaySupport.AUTO_STOP[kind] or def.lifetime ~= nil then
		local life = def.lifetime or 1.4
		task.delay(life, function()
			if handle:isPlaying() then
				handle:stop()
			end
		end)
	end

	if not ok then
		Logger.warn("VfxEngine", `play failed {effectId}: {err}`)
		handle:stop()
		return nil
	end

	return handle
end

function VfxEngine:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:stopAll()
	self._trove:Destroy()
end

return VfxEngine
