--!strict

local types = require(script.Parent.types)

local MockData = {}

function MockData.earnings(): types.OfflineEarningsData
    return {
        headline = "While OFFLINE  you earned..",
        currentText = "$1.75B",
        doubleText = "$1.75B",
        doublePrice = 49,
    }
end

return MockData
