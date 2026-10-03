--!strict

local MutationShineLogic = require("../src/shared/util/MutationShineLogic")

return {
    ["pose 0 static"] = function(expect)
        local p = MutationShineLogic.pose(0, 9, -73)
        expect(p.offset.x).toEqual(0)
        expect(p.rotation).toEqual(-73)
    end,
    ["V2 is horizontal sine"] = function(expect)
        local p = MutationShineLogic.pose(2, math.pi / (2 * 1.4), 0)
        expect(math.abs(p.offset.x) > 0.5).toBeTruthy()
        expect(p.offset.y).toEqual(0)
    end,
}
