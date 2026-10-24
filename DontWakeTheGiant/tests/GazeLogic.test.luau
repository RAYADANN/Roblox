--!strict
local GazeLogic = require("../src/shared/util/GazeLogic")

local CFG = {
    GAZE_HALF_ANGLE = 35,
    GAZE_RANGE = 160,
    GAZE_HEAVY_WEIGHT = 4,
    MOVING_MIN_SPEED = 2,
    GAZE_SWEEP_HALF_DEG = 135,
    GAZE_TURN_DEG_PER_SEC = 20,
}

local function target(dx: number, dz: number, speed: number, sneaking: boolean, weight: number)
    return { dx = dx, dz = dz, horizontalSpeed = speed, sneaking = sneaking, carryWeight = weight }
end

return {
    ["isConspicuous: замерший невидим"] = function(expect)
        expect(GazeLogic.isConspicuous(target(10, 0, 0, false, 5), CFG)).toBeFalsy()
    end,
    ["isConspicuous: крадущийся с весом 3 невидим, с весом 4 виден"] = function(
        expect
    )
        expect(GazeLogic.isConspicuous(target(10, 0, 8, true, 3), CFG)).toBeFalsy()
        expect(GazeLogic.isConspicuous(target(10, 0, 8, true, 4), CFG)).toBeTruthy()
    end,
    ["isConspicuous: идущий виден"] = function(expect)
        expect(GazeLogic.isConspicuous(target(10, 0, 16, false, 0), CFG)).toBeTruthy()
    end,
    ["inCone: прямо по взгляду и за краем"] = function(expect)
        expect(GazeLogic.inCone(0, target(100, 0, 0, false, 0), CFG)).toBeTruthy()
        expect(GazeLogic.inCone(0, target(100, 100, 0, false, 0), CFG)).toBeFalsy()
        expect(GazeLogic.inCone(45, target(100, 100, 0, false, 0), CFG)).toBeTruthy()
    end,
    ["inCone: дальше 160 не видно"] = function(expect)
        expect(GazeLogic.inCone(0, target(161, 0, 0, false, 0), CFG)).toBeFalsy()
    end,
    ["yawAt: пинг-понг по дуге"] = function(expect)
        expect(GazeLogic.yawAt(0, CFG)).toBeCloseTo(-135)
        expect(GazeLogic.yawAt(13.5, CFG)).toBeCloseTo(135)
        expect(GazeLogic.yawAt(20.25, CFG)).toBeCloseTo(0)
    end,
}
