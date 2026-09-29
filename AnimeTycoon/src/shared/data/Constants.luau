--!strict
-- Global AnimeTycoon numbers. Logic reads these; Managers do not hardcode.

local Constants = {}

Constants.START_COINS = 100
Constants.OFFER_COUNT = 5
Constants.SLOT_COUNT = 10
Constants.INVENTORY_MAX = 20

-- Rebirth (kept for starter Upgrade/RebirthLogic demos).
Constants.REBIRTH_BASE_COST = 50000
Constants.REBIRTH_EXPONENT = 5
Constants.REBIRTH_MULT_PER = 0.1

Constants.UPGRADE_COST_MULT = 1.15

Constants.MINE_COOLDOWN_SEC = 0.08
Constants.MAX_MINE_BATCH = 8

return Constants
