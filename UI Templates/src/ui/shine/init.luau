--!strict
--[[
	Portable shine kit — copy `src/ui/shine/` into any React-Lua project.

	Requires: Packages.Flipper, Packages.React
]]

local ShineDriver = require(script.ShineDriver)
local useScrollVisibility = require(script.useScrollVisibility)
local useShineRef = require(script.useShineRef)
local visibility = require(script.visibility)

local DEFAULT_SHINE_WIDTH = 0.28

local function startX(shineWidth: number?): number
    local w = shineWidth or DEFAULT_SHINE_WIDTH
    return select(1, ShineDriver.sweepRange(w))
end

return {
    ShineDriver = ShineDriver,
    useShineRef = useShineRef,
    useScrollVisibility = useScrollVisibility,
    isInScrollView = visibility.isInScrollView,
    sweepRange = ShineDriver.sweepRange,
    startX = startX,
}
