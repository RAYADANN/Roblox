local CombatAudioLogic = require("@shared/util/CombatAudioLogic")

return {
    ["remoteFireVolume: full within near band"] = function(expect)
        expect(CombatAudioLogic.remoteFireVolume(0, 24, 160)).toEqual(1)
        expect(CombatAudioLogic.remoteFireVolume(24, 24, 160)).toEqual(1)
    end,
    ["remoteFireVolume: silent beyond max"] = function(expect)
        expect(CombatAudioLogic.remoteFireVolume(160, 24, 160)).toEqual(0)
        expect(CombatAudioLogic.remoteFireVolume(999, 24, 160)).toEqual(0)
    end,
    ["remoteFireVolume: mid range quieter than near"] = function(expect)
        local mid = CombatAudioLogic.remoteFireVolume(90, 24, 160)
        local near = CombatAudioLogic.remoteFireVolume(30, 24, 160)
        expect(mid < near).toEqual(true)
        expect(mid > 0).toEqual(true)
    end,
}
