--!strict

local ImageIds = require(script.ImageIds)
local SimPopBlock = require(script.SimPopBlock)

return {
    ImageIds = ImageIds,
    Block = ImageIds.Block,
    LongBlock = ImageIds.LongBlock,
    TONES = ImageIds.TONES,
    SimPopBlock = SimPopBlock,
    SimPopLongBlock = require(script.SimPopLongBlock),
}
