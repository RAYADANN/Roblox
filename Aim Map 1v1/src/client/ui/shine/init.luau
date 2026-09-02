--!strict
-- Portable shine kit (UI Templates → Aim Map).

local ShineDriver = require(script.ShineDriver)
local useShineRef = require(script.useShineRef)

local DEFAULT_SHINE_WIDTH = 0.28

local function startX(shineWidth: number?): number
    local w = shineWidth or DEFAULT_SHINE_WIDTH
    return select(1, ShineDriver.sweepRange(w))
end

return {
    ShineDriver = ShineDriver,
    useShineRef = useShineRef,
    sweepRange = ShineDriver.sweepRange,
    startX = startX,
}
