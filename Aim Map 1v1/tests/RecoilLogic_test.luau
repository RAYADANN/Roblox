local RecoilLogic = require("@shared/util/RecoilLogic")

return {
    ["kick: pitch up, yaw from unit"] = function(expect)
        local p, y, keep = RecoilLogic.kick(0.5, false)
        expect(p > 0).toEqual(true)
        expect(y).toBeCloseTo(0, 5)
        expect(keep > 0 and keep < p).toEqual(true)
        local _, yL = RecoilLogic.kick(0, false)
        local _, yR = RecoilLogic.kick(1, false)
        expect(yL < 0).toEqual(true)
        expect(yR > 0).toEqual(true)
    end,
    ["kick: reduceMotion scales down"] = function(expect)
        local pFull = RecoilLogic.kick(0.5, false)
        local pRed = RecoilLogic.kick(0.5, true)
        expect(pRed < pFull).toEqual(true)
    end,
    ["decay: approaches zero"] = function(expect)
        local p, y = math.rad(2), math.rad(1)
        for _ = 1, 40 do
            p, y = RecoilLogic.decay(p, y, 1 / 60, 14)
        end
        expect(math.abs(p)).toBeCloseTo(0, 3)
        expect(math.abs(y)).toBeCloseTo(0, 3)
    end,
    ["clampStack: caps pitch"] = function(expect)
        local cfg = RecoilLogic.defaultConfig()
        local p = RecoilLogic.clampStack(math.rad(99), 0, cfg)
        expect(p).toBeCloseTo(math.rad(cfg.maxPitchDeg), 5)
    end,
}
