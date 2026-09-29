--!strict

local types = require(script.Parent.types)

local MockData = {}

function MockData.hud(): types.HudData
    return {
        moneyText = "$100M",
    }
end

return MockData
