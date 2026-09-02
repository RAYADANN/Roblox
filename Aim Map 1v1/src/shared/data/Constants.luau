--!strict
-- Глобальные балансовые числа. В логике — ссылки, не литералы.

local Constants = {}

-- Duel / USP
Constants.MATCH_FIRST_TO = 5
Constants.MATCH_PLAYER_HP = 100

Constants.USP_DAMAGE_BODY = 34
Constants.USP_DAMAGE_HEAD = 100
Constants.USP_FIRE_COOLDOWN_SEC = 0.22
Constants.USP_MAX_RANGE_STUDS = 400
Constants.USP_ORIGIN_SLACK_STUDS = 8
-- Local FP camera punch (LookController); visual recover + small aim keep.
Constants.USP_RECOIL_RECOVER_RATE = 14

-- Local FP tracer start in camera space (right, up, forward). Avoids "out of eyes" look.
Constants.FP_TRACER_MUZZLE_RIGHT = 0.42
Constants.FP_TRACER_MUZZLE_UP = 0.28
Constants.FP_TRACER_MUZZLE_FORWARD = 1.55

-- Remote gunfire hearability (enemy / bot shots on other clients)
Constants.REMOTE_FIRE_FULL_VOLUME_STUDS = 28
Constants.REMOTE_FIRE_MAX_STUDS = 170
Constants.REMOTE_FIRE_AUDIBLE_MIN = 0.04
-- Even up close, enemy fire stays under your own shot so mixes don't wash out.
Constants.REMOTE_FIRE_NEAR_CAP = 0.55

-- Footsteps (local full; remotes quieter by distance)
Constants.FOOTSTEP_STRIDE_STUDS = 2.6
Constants.FOOTSTEP_MIN_SPEED = 2.5
Constants.FOOTSTEP_FULL_VOLUME_STUDS = 18
Constants.FOOTSTEP_MAX_STUDS = 95
Constants.FOOTSTEP_AUDIBLE_MIN = 0.05
Constants.FOOTSTEP_REMOTE_NEAR_CAP = 0.42

-- Take-damage UI (Valorant-style vignette + direction chevron)
Constants.DAMAGE_INDICATOR_DURATION_SEC = 0.85
Constants.DAMAGE_VIGNETTE_DURATION_SEC = 0.45
-- Full-bleed screen wash (IgnoreGuiInset): red on hit, blue on kill
Constants.COMBAT_FLASH_HOLD_SEC = 0.1
Constants.COMBAT_FLASH_DAMAGE_OPACITY = 0.5
Constants.COMBAT_FLASH_KILL_OPACITY = 0.42

Constants.FIRE_RATE_MAX_PER_SEC = 8

Constants.REMATCH_TIMEOUT_SEC = 30

Constants.DEFAULT_SKIN_ID = "usp_default"

Constants.FLEX_SKIN_ATTRIBUTE = "AimFlexSkinId"
Constants.EQUIPPED_SKIN_ATTRIBUTE = "AimEquippedSkinId"
-- Studio Workspace "R15 Dummy" assigned to all players / bots
Constants.UNIFORM_RIG_ATTRIBUTE = "AimUniformRig"

-- CS-style death ragdoll (players, duel bot, practice dummies)
Constants.RAGDOLL_ATTRIBUTE = "AimRagdolled"
Constants.RAGDOLL_SPEED = 48
Constants.RAGDOLL_UP_BIAS = 14
Constants.RAGDOLL_SPIN = 18
-- Death cam, then both sides reset. Server owns respawn (CharacterAutoLoads off).
Constants.ROUND_RESET_DELAY_SEC = 4

-- Solo practice targets (Studio / alone)
Constants.PRACTICE_DUMMY_ATTRIBUTE = "AimPracticeDummy"
Constants.PRACTICE_DUMMY_COUNT = 4
Constants.PRACTICE_DUMMY_RESPAWN_SEC = 2
Constants.PRACTICE_DUMMY_HP = 100

-- Duel bot (synthetic opponent, not a Player)
Constants.BOT_USER_ID = -1
Constants.BOT_DISPLAY_NAME = "BOT"
Constants.BOT_ATTRIBUTE = "AimDuelBot"
Constants.BOT_HP = 100
Constants.BOT_WALK_SPEED = 14
Constants.BOT_TICK_HZ = 25
Constants.BOT_REACTION_MIN_SEC = 0.22
Constants.BOT_REACTION_MAX_SEC = 0.42
-- Slower than player USP cadence — human-like shot spacing.
Constants.BOT_FIRE_COOLDOWN_SEC = 0.45
Constants.BOT_FIRE_JITTER_SEC = 0.12
Constants.BOT_AIM_ERROR_MAX_RAD = 0.085
Constants.BOT_ROUND_GRACE_SEC = 0.7
Constants.BOT_ENGAGE_MIN_STUDS = 28
Constants.BOT_ENGAGE_MAX_STUDS = 52
Constants.BOT_STRAFE_PERIOD_SEC = 1.15
Constants.BOT_TARGET_MEMORY_SEC = 1.2
Constants.BOT_LOOK_LERP = 0.22
Constants.BOT_REMATCH_DELAY_SEC = 0.55

-- Look sensitivity (profile)
Constants.LOOK_SENSITIVITY_DEFAULT = 1
Constants.LOOK_SENSITIVITY_MIN = 0.2
Constants.LOOK_SENSITIVITY_MAX = 3
Constants.LOOK_SENSITIVITY_STEP = 0.1

-- FP camera: eye point above HumanoidRootPart (not Head mesh / LockFirstPerson zoom).
Constants.FP_EYE_HEIGHT = 2.15

-- FP viewmodel extra offset after eye-align. Lift so Idle arms sit in the lower FOV.
Constants.VIEWMODEL_OFFSET_RIGHT = 0.08
Constants.VIEWMODEL_OFFSET_UP = 0.2
Constants.VIEWMODEL_OFFSET_FORWARD = 0.25
Constants.VIEWMODEL_ATTRIBUTE = "AimViewModel"

-- Crosshair wall (profile + shoot-to-select panels)
Constants.DEFAULT_CROSSHAIR_ID = "classic"
Constants.CROSSHAIR_PANEL_ATTRIBUTE = "AimCrosshairId"

-- Starter leftovers (kept for existing *Logic tests / unused economy)
Constants.REBIRTH_BASE_COST = 50000
Constants.REBIRTH_EXPONENT = 5
Constants.REBIRTH_MULT_PER = 0.1
Constants.UPGRADE_COST_MULT = 1.15

return Constants
