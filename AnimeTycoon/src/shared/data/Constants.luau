--!strict
-- Global AnimeTycoon numbers. Logic reads these; Managers do not hardcode.

local Constants = {}

Constants.START_COINS = 100
Constants.OFFER_COUNT = 5
--- Stand pads unlocked at start (Stand1); +1 per `pad` upgrade (max 5).
Constants.BASE_UNLOCKED_PADS = 1
Constants.SLOTS_PER_FLOOR = 10
Constants.FLOOR_COUNT = 3
Constants.BASE_UNLOCKED_SLOTS = 10
Constants.SLOT_COUNT = Constants.SLOTS_PER_FLOOR * Constants.FLOOR_COUNT -- 30
Constants.INVENTORY_MAX = 20
Constants.SELL_CRATE_MAX = 10

-- Rebirth (kept for starter Upgrade/RebirthLogic demos).
Constants.REBIRTH_BASE_COST = 50000
Constants.REBIRTH_EXPONENT = 5
Constants.REBIRTH_MULT_PER = 0.1

--- Default shop-upgrade growth. Tracks with 40–50 levels set a gentler costGrowth.
Constants.UPGRADE_COST_MULT = 1.45

--- Placed hero level. Income compounds; the next level's price is the extra
--- coins/sec times a payback that itself grows, so late levels stay a sink.
Constants.HERO_MAX_LEVEL = 50
Constants.HERO_LEVEL_GROWTH = 1.15
Constants.HERO_LEVEL_PAYBACK_SEC = 45
Constants.HERO_LEVEL_PAYBACK_GROWTH = 1.15

--- Right-rail Lucky/Money offers: 24h from first HUD view.
Constants.BOOST_OFFER_DURATION_SEC = 24 * 3600

--- Offline earnings: ignore short disconnects; cap long AFK.
Constants.OFFLINE_EARNINGS_MIN_SEC = 60
Constants.OFFLINE_EARNINGS_MAX_SEC = 8 * 3600

Constants.MINE_COOLDOWN_SEC = 0.08
Constants.MAX_MINE_BATCH = 8

return Constants
