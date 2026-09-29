--!strict
-- Global showroom numbers. Logic reads these; Managers do not hardcode.

local Constants = {}

Constants.START_COINS = 50
Constants.SLOT_COUNT = 6
Constants.FAVORITE_SLOT_COUNT = 5
Constants.OFFER_COUNT = 3
Constants.INVENTORY_MAX = 20
Constants.PROFILE_KEY = "ShowroomPlayerData_v3"
-- Stand-on Place.Button: one place attempt per step-on.
Constants.PLACE_BUTTON_RADIUS = 4.5
Constants.PLACE_BUTTON_REENTRY_SEC = 0.45
-- Cube.001 / Cube.002 press dip (incubator + FavoritePlace).
Constants.PAD_PRESS_DEPTH = 0.35
Constants.PAD_PRESS_DOWN_SEC = 0.08
Constants.PAD_PRESS_UP_SEC = 0.12

-- Visitor crowd (client soft caps; server publishes target per stand).
Constants.NPC_PER_STAND_MAX = 14
Constants.NPC_TOTAL_SOFT_CAP = 48

-- Rebirth (multiplier for auction; full rebirth loop may come later).
Constants.REBIRTH_BASE_COST = 50000
Constants.REBIRTH_EXPONENT = 5
Constants.REBIRTH_MULT_PER = 1 -- valueMultiplier = 1 + rebirths

-- Auction
Constants.AUCTION_MAX_RUNS = 3
Constants.AUCTION_DURATION_SEC = 7

return Constants
