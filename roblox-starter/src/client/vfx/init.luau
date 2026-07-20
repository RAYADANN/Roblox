--!strict
-- Публичный вход VFX-движка. См. docs/VFX_ENGINE.md

local VfxEngine = require(script.VfxEngine)
local Camera = require(script.camera)

local ImpactBurst = require(script.presets.ImpactBurst)
local DashTrail = require(script.presets.DashTrail)
local CastBurst = require(script.presets.CastBurst)
local PowerAura = require(script.presets.PowerAura)
local HandGlow = require(script.presets.HandGlow)
local NeonBolt = require(script.presets.NeonBolt)
local DamageFlash = require(script.presets.DamageFlash)
local HitConfirm = require(script.presets.HitConfirm)
local FlipbookBurst = require(script.presets.FlipbookBurst)
local NeonImpact = require(script.presets.NeonImpact)
local SmokeDash = require(script.presets.SmokeDash)

export type Deps = VfxEngine.Deps
export type PlayContext = VfxEngine.PlayContext
export type VfxEngineType = VfxEngine.VfxEngine
export type EffectHandle = VfxEngine.EffectHandle
export type CameraMode = VfxEngine.CameraMode

local BUILTIN = {
	ImpactBurst,
	DashTrail,
	CastBurst,
	PowerAura,
	HandGlow,
	NeonBolt,
	DamageFlash,
	HitConfirm,
	FlipbookBurst,
	NeonImpact,
	SmokeDash,
}

local VFX = {}

function VFX.create(deps: Deps?): VfxEngine.VfxEngine
	local engine = VfxEngine.new(deps)
	for _, def in BUILTIN do
		engine:register(def)
	end
	return engine
end

VFX.VfxEngine = VfxEngine
VFX.Camera = Camera
VFX.presets = {
	ImpactBurst = ImpactBurst,
	DashTrail = DashTrail,
	CastBurst = CastBurst,
	PowerAura = PowerAura,
	HandGlow = HandGlow,
	NeonBolt = NeonBolt,
	DamageFlash = DamageFlash,
	HitConfirm = HitConfirm,
	FlipbookBurst = FlipbookBurst,
	NeonImpact = NeonImpact,
	SmokeDash = SmokeDash,
}

return VFX
