--!strict
local PlotOwnership = require("../src/shared/util/PlotOwnership")

return {
    ["owns: matching user id"] = function(expect)
        expect(PlotOwnership.owns(42, 42)).toEqual(true)
    end,
    ["owns: empty and foreign plots are not owned"] = function(expect)
        expect(PlotOwnership.owns(nil, 42)).toEqual(false)
        expect(PlotOwnership.owns(0, 42)).toEqual(false)
        expect(PlotOwnership.owns(7, 42)).toEqual(false)
    end,
}
