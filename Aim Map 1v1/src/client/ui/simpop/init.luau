--!strict

local ImageIds = require(script.ImageIds)
local SimPopButton = require(script.SimPopButton)

return {
    ImageIds = ImageIds,
    SimPop = ImageIds.SimPop,
    TONES = ImageIds.TONES,
    ORIENTATIONS = ImageIds.ORIENTATIONS,
    SimPopButton = SimPopButton,
    SimPopChrome = require(script.SimPopChrome),
    block = require(script.block),
}
