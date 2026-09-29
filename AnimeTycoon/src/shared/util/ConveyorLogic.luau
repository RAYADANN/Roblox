--!strict
-- Pure conveyor travel + delivery timing. CI-tested.

local ConveyorLogic = {}

-- Base travel time (sec) along ramp path before payout.
local BASE_TRAVEL_SEC = 3.2

function ConveyorLogic.travelDuration(slotIndex: number): number
    -- Slight stagger by slot so lanes don't sync perfectly.
    local idx = math.max(1, math.floor(slotIndex))
    return BASE_TRAVEL_SEC + (idx % 5) * 0.12
end

function ConveyorLogic.arriveAt(nowSec: number, slotIndex: number): number
    return nowSec + ConveyorLogic.travelDuration(slotIndex)
end

return ConveyorLogic
