--!strict
-- Smoke for Roblox text FX lab poses.

local TextFxLogic = require("../src/client/ui/stories/robloxTextFx/TextFxLogic")

return {
    ["pose returns fields for each variant"] = function(expect)
        for v = 1, 10 do
            local pose = TextFxLogic.pose(v, 0.5)
            expect(typeof(pose)).toEqual("table")
        end
        local sweep = TextFxLogic.pose(1, 0)
        expect(sweep.offsetX).toEqual(-1)
        local mid = TextFxLogic.pose(1, 0.7)
        expect(mid.offsetX ~= nil).toBeTruthy()
        local bounce = TextFxLogic.pose(3, 0)
        expect(bounce.scale).toEqual(1)
        local hue = TextFxLogic.pose(7, 0)
        expect(hue.hue).toEqual(0)
    end,

    ["labels cover 1..10"] = function(expect)
        local labels = TextFxLogic.labels()
        for i = 1, 10 do
            expect(typeof(labels[i])).toEqual("string")
        end
    end,
}
