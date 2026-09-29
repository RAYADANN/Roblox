--!strict
-- Global farm numbers. Logic reads these; do not hardcode in Managers.

local Constants = {}

Constants.UPGRADE_COST_MULT = 1.15

Constants.START_COINS = 50
-- Live plots use DummyItems markers. Fallback HUD cap = floors × per floor.
Constants.SLOT_FLOORS = 8
Constants.SLOTS_PER_FLOOR = 5
Constants.MAX_SLOTS = Constants.SLOT_FLOORS * Constants.SLOTS_PER_FLOOR
Constants.MAX_GROUND_DROPS = 40
Constants.MERGE_COUNT = 3
Constants.BUY_TIER = 1
-- Production upgrade: next buy tier = BUY_TIER + productionLevel.
-- Summon gates for upgrade 1 / 2 / 3… = 100 / 150 / 200…
Constants.PRODUCTION_SUMMON_BASE = 100
Constants.PRODUCTION_SUMMON_STEP = 50

-- Early curve is flat enough that Buy 100 is reachable in a short session;
-- late buys still grow exponentially via UNIT_COST_MULT.
Constants.UNIT_BASE_COST = 1
Constants.UNIT_COST_MULT = 1.05

Constants.PROCESS_BASE_PER_SEC = 2
-- Late curve: +10% of current rate. Early levels use MIN_DELTA instead so
-- the first upgrades feel chunky (2→3→4…) instead of +0.2/sec.
Constants.PROCESS_UPGRADE_FRAC = 0.1
Constants.PROCESS_UPGRADE_MIN_DELTA = 1
Constants.PROCESS_UPGRADE_BASE = 25
Constants.PROCESS_UPGRADE_MULT = 1.35

Constants.PRODUCTION_UPGRADE_BASE = 75
Constants.PRODUCTION_UPGRADE_MULT = 1.4
Constants.LAY_BASE_SEC = 4
Constants.LAY_MIN_SEC = 1.4

Constants.GROUP_REWARD = 25
Constants.GROUP_REWARD_COOLDOWN_SEC = 600
-- HUD cash pills (DevProducts): grant = max(balance, FLOOR) × mult so early packs
-- still feel worth Robux (see MoneyOfferLogic).
Constants.MONEY_OFFER_BALANCE_FLOOR = 1000
-- Exclusive HUD offer: visible for this long after first view.
Constants.EXCLUSIVE_OFFER_DURATION_SEC = 72 * 3600
Constants.MULTIPLIER_MIN = 0.5
Constants.MULTIPLIER_MAX = 1.5
Constants.MULTIPLIER_STEP = 0.1
Constants.MULTIPLIER_PERIOD_SEC = 30

Constants.OFFLINE_CAP_SEC = 7200
Constants.CASH_PER_EGG = 1
-- Dummy drop cash: tier 1 base, each merge level doubles. Kind in DropDatabase is a multiplier.
Constants.DROP_TIER_BASE = 10
Constants.DROP_TIER_MULT = 2

Constants.PAD_STAND_RADIUS = 6.5
Constants.PAD_COOLDOWN_SEC = 0.55
Constants.PAD_PRESS_DEPTH = 0.35
Constants.PAD_PRESS_DOWN_SEC = 0.08
Constants.PAD_PRESS_UP_SEC = 0.12
-- Must fully leave the pad for this long before another press is allowed.
Constants.PAD_REENTRY_SEC = 0.08

-- Drops: spawn into Stand trough (local -Look), then conveyor physics slides them to the tip.
Constants.DROP_SPAWN_Y = -3.2
Constants.DROP_SPAWN_INTO_Z = -8
Constants.DROP_SPAWN_INTO_SPREAD = 2.2
Constants.DROP_SPAWN_JITTER_X = 1.6
Constants.DROP_CONVEYOR_SPEED = 14
Constants.DROP_DENSITY = 0.4
Constants.DROP_FRICTION = 0.15
Constants.DROP_ELASTICITY = 0
Constants.DROP_DESPAWN_Y = -20
-- Collect when the drop is near the player (no Touched / collision required).
Constants.DROP_PICKUP_RADIUS = 5
-- Auto Collect: after sliding on Stand, pick up near tip (Plane), not at spawn.
Constants.DROP_AUTO_COLLECT_RADIUS = 10
Constants.DROP_PICKUP_INTERVAL_SEC = 0.05

return Constants
