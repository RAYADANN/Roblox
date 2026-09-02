--!strict
-- Публичный вход VFX-движка. См. docs/VFX_ENGINE.md

local Camera = require(script.camera)
local VfxEngine = require(script.VfxEngine)

local CastBurst = require(script.presets.CastBurst)
local ChainStrike = require(script.presets.ChainStrike)
local CinemaCataclysm = require(script.presets.CinemaCataclysm)
local CritImpact = require(script.presets.CritImpact)
local DamageFlash = require(script.presets.DamageFlash)
local DashTrail = require(script.presets.DashTrail)
local EggHatch = require(script.presets.EggHatch)
local FlipbookBurst = require(script.presets.FlipbookBurst)
local GroundSlam = require(script.presets.GroundSlam)
local HandGlow = require(script.presets.HandGlow)
local HealPulse = require(script.presets.HealPulse)
local HitConfirm = require(script.presets.HitConfirm)
local ImpactBurst = require(script.presets.ImpactBurst)
local MeguminBlast = require(script.presets.MeguminBlast)
local MeteorStrike = require(script.presets.MeteorStrike)
local NeonBolt = require(script.presets.NeonBolt)
local NeonImpact = require(script.presets.NeonImpact)
local OreShatter = require(script.presets.OreShatter)
local PetAppear = require(script.presets.PetAppear)
local PowerAura = require(script.presets.PowerAura)
local SmokeDash = require(script.presets.SmokeDash)
local UltimateCharge = require(script.presets.UltimateCharge)

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
    CritImpact,
    GroundSlam,
    HealPulse,
    UltimateCharge,
    ChainStrike,
    MeteorStrike,
    OreShatter,
    PetAppear,
    EggHatch,
    MeguminBlast,
    CinemaCataclysm,
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
    CritImpact = CritImpact,
    GroundSlam = GroundSlam,
    HealPulse = HealPulse,
    UltimateCharge = UltimateCharge,
    ChainStrike = ChainStrike,
    MeteorStrike = MeteorStrike,
    OreShatter = OreShatter,
    PetAppear = PetAppear,
    EggHatch = EggHatch,
    MeguminBlast = MeguminBlast,
    CinemaCataclysm = CinemaCataclysm,
}

return VFX
