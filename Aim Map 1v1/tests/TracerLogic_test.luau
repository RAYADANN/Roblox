local TracerLogic = require("@shared/util/TracerLogic")

return {
    ["fpMuzzleWorld: forward offset moves along look"] = function(expect)
        local x, y, z = TracerLogic.fpMuzzleWorld(
            0,
            0,
            0,
            1,
            0,
            0, -- right
            0,
            1,
            0, -- up
            0,
            0,
            -1, -- look (-Z)
            0,
            0,
            2 -- 2 studs forward
        )
        expect(x).toBeCloseTo(0, 5)
        expect(y).toBeCloseTo(0, 5)
        expect(z).toBeCloseTo(-2, 5)
    end,
    ["fpMuzzleWorld: right+down offset"] = function(expect)
        local x, y, z =
            TracerLogic.fpMuzzleWorld(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1, 0.5, -0.25, 1)
        expect(x).toBeCloseTo(0.5, 5)
        expect(y).toBeCloseTo(-0.25, 5)
        expect(z).toBeCloseTo(-1, 5)
    end,
    ["fpTraceEnd: converges on the aim hit"] = function(expect)
        -- muzzle offset +0.5 X, hit at (0,0,-10) → streak ends on the hit, not parallel
        local x, y, z = TracerLogic.fpTraceEnd(0.5, 0, 0, 0, 0, -10)
        expect(x).toBeCloseTo(0, 5)
        expect(y).toBeCloseTo(0, 5)
        expect(z).toBeCloseTo(-10, 5)
    end,
    ["muzzleAimDelta: Shoot toward aim point"] = function(expect)
        local dx, dy, dz = TracerLogic.muzzleAimDelta(0.5, -0.8, 0, 0, 0, -10)
        expect(dx).toBeCloseTo(-0.5, 5)
        expect(dy).toBeCloseTo(0.8, 5)
        expect(dz).toBeCloseTo(-10, 5)
    end,
}
