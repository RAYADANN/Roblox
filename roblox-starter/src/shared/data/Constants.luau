--!strict
-- Глобальные балансовые числа. В логике — ссылки, не литералы.

local Constants = {}

Constants.REBIRTH_BASE_COST = 50000
Constants.REBIRTH_EXPONENT = 5
Constants.REBIRTH_MULT_PER = 0.1

Constants.UPGRADE_COST_MULT = 1.15

Constants.MINE_COOLDOWN_SEC = 0.08
Constants.MAX_MINE_BATCH = 8

return Constants
