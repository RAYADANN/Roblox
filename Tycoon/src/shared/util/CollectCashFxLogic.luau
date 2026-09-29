--!strict
-- How many world coins to spawn for a Collect Cash payout.

local CollectCashFxLogic = {}

function CollectCashFxLogic.coinCount(gained: number): number
    local g = math.max(0, gained)
    if g <= 0 then
        return 0
    end
    local raw = 5 + math.log10(math.max(1, g)) * 4
    return math.clamp(math.floor(raw + 0.5), 5, 16)
end

return CollectCashFxLogic
