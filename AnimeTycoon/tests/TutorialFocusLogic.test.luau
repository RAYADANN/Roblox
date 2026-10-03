--!strict
local TutorialFocusLogic = require("../src/shared/util/TutorialFocusLogic")

return {
    ["lerpAngle: shortest path across wrap"] = function(expect)
        expect(TutorialFocusLogic.lerpAngle(170, -170, 0.5)).toBeCloseTo(180, 1e-4)
        expect(TutorialFocusLogic.lerpAngle(0, 90, 0.5)).toEqual(45)
    end,
    ["arrowOutsideFrame: tip down sits above the hole"] = function(expect)
        local x, y, deg = TutorialFocusLogic.arrowOutsideFrame(0.5, 0.5, 0.1, 0.08, 0, 180, 0.02)
        expect(math.floor(deg + 0.5)).toEqual(180)
        expect(x).toEqual(0.5)
        expect(y < 0.42).toEqual(true)
        expect(y).toBeCloseTo(0.4, 1e-6)
    end,
    ["arrowOutsideFrame: tip right sits left so off-screen stays visible"] = function(expect)
        -- outward opposite tip: tip 90 (right) → place on left of hole
        local x, y, deg = TutorialFocusLogic.arrowOutsideFrame(0.9, 0.5, 0.1, 0.08, 270, 90, 0.02)
        expect(math.floor(deg + 0.5)).toEqual(90)
        expect(y).toEqual(0.5)
        expect(x < 0.9).toEqual(true)
    end,
    ["arrowDeg: up / right / down"] = function(expect)
        expect(math.floor(TutorialFocusLogic.arrowDeg(0, -1) + 0.5)).toEqual(0)
        expect(math.floor(TutorialFocusLogic.arrowDeg(1, 0) + 0.5)).toEqual(90)
        expect(math.floor(TutorialFocusLogic.arrowDeg(0, 1) + 0.5)).toEqual(180)
    end,
    ["clampToEdge: right and corner"] = function(expect)
        local x, y = TutorialFocusLogic.clampToEdge(2, 0.5, 0.1)
        expect(x).toEqual(0.9)
        expect(y).toEqual(0.5)
        local cx, cy = TutorialFocusLogic.clampToEdge(2, 2, 0.1)
        expect(cx).toEqual(0.9)
        expect(cy).toEqual(0.9)
    end,
    ["fromViewport: on-screen keeps pad and points down"] = function(expect)
        local f = TutorialFocusLogic.fromViewport(100, 80, 10, 200, 200, 0.1)
        expect(f.onScreen).toEqual(true)
        expect(f.x).toEqual(0.5)
        expect(f.y).toEqual(0.4)
        expect(f.arrowDeg).toEqual(180)
    end,
    ["fromViewport: off-screen moves hole to the edge"] = function(expect)
        local f = TutorialFocusLogic.fromViewport(400, 100, 10, 200, 200, 0.1)
        expect(f.onScreen).toEqual(false)
        expect(f.x).toEqual(0.9)
        expect(f.y).toEqual(0.5)
        expect(math.floor(f.arrowDeg + 0.5)).toEqual(90)
    end,
    ["fromViewport: behind camera still updates (does not freeze)"] = function(expect)
        local f = TutorialFocusLogic.fromViewport(50, 50, -8, 200, 200, 0.1)
        expect(f.onScreen).toEqual(false)
        expect(typeof(f.x) == "number").toEqual(true)
        expect(typeof(f.y) == "number").toEqual(true)
    end,
    ["changed: ignores sub-pixel jitter"] = function(expect)
        local a = { x = 0.5, y = 0.4, onScreen = true, arrowDeg = 180 }
        local b = { x = 0.501, y = 0.4, onScreen = true, arrowDeg = 180 }
        expect(TutorialFocusLogic.changed(a, b)).toEqual(false)
        local c = { x = 0.52, y = 0.4, onScreen = true, arrowDeg = 180 }
        expect(TutorialFocusLogic.changed(a, c)).toEqual(true)
    end,
}
