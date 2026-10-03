--!strict

local types = require(script.Parent.types)

local MockData = {}

function MockData.hud(): types.HudData
    return {
        coins = 100_000_000,
    }
end

return MockData
