--!strict
-- Владелец VFX-движка на клиенте. Паттерн как SoundManager.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.shared.util.Logger)

local VFX = require(script.Parent.Parent.vfx)
local SettingsManager = require(script.Parent.SettingsManager)
local SoundManager = require(script.Parent.SoundManager)

local VfxController = {}

local _engine: VFX.VfxEngineType? = nil

export type StartConfig = {
	cameraMode: VFX.CameraMode?,
	onShakeOffset: ((Vector3) -> ())?,
}

function VfxController.start(config: StartConfig?)
	if _engine then
		return
	end
	_engine = VFX.create({
		isReduceMotion = SettingsManager.isReduceMotion,
		playSound = SoundManager.play,
		cameraMode = if config then config.cameraMode else "HumanoidOffset",
		onShakeOffset = if config then config.onShakeOffset else nil,
	})
	Logger.info("VfxController", "engine ready")
end

function VfxController.get(): VFX.VfxEngineType
	assert(_engine, "VfxController.start() first")
	return _engine
end

function VfxController.play(presetId: string, ctx: VFX.PlayContext): VFX.EffectHandle?
	return VfxController.get():play(presetId, ctx)
end

function VfxController.stopAll()
	if _engine then
		_engine:stopAll()
	end
end

function VfxController.setCameraMode(mode: VFX.CameraMode, onShakeOffset: ((Vector3) -> ())?)
	local engine = VfxController.get()
	local driver = VFX.Camera.resolve({
		mode = mode,
		onShakeOffset = onShakeOffset,
	})
	engine:setCameraDriver(driver)
end

function VfxController.destroy()
	if _engine then
		_engine:destroy()
		_engine = nil
	end
end

return VfxController
