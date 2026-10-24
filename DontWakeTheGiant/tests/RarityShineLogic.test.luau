--!strict

local RarityShineLogic = require("../src/shared/util/RarityShineLogic")

return {
    ["pose 0 is static"] = function(expect)
        local p = RarityShineLogic.pose(0, 1.5, 90)
        expect(p.offset.x).toEqual(0)
        expect(p.offset.y).toEqual(0)
        expect(p.rotation).toEqual(90)
    end,
    ["R2 pendulum stays near base"] = function(expect)
        local p = RarityShineLogic.pose(2, 0, 90)
        expect(p.rotation).toEqual(90)
        local p2 = RarityShineLogic.pose(2, math.pi / (2 * 1.8), 90)
        expect(math.abs(p2.rotation - 90) > 10).toBeTruthy()
        expect(math.abs(p2.rotation - 90) < 35).toBeTruthy()
    end,
    ["R5 ping-pong returns to start"] = function(expect)
        local a = RarityShineLogic.pose(5, 0, 0)
        local b = RarityShineLogic.pose(5, 2.0, 0)
        expect(math.abs(a.offset.x - b.offset.x) < 0.01).toBeTruthy()
    end,
}
