--!strict

local ImageIds = require(script.ImageIds)
local SimPopBlock = require(script.SimPopBlock)

return {
    ImageIds = ImageIds,
    Block = ImageIds.Block,
    TONES = ImageIds.TONES,
    SimPopBlock = SimPopBlock,
}
