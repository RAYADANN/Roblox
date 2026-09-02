return {
    ["maps player data to hud"] = function(expect)
        local buildHudPayload = require("@shared/util/buildHudPayload")
        local payload = buildHudPayload.fromPlayerData({
            wins = 3,
            losses = 1,
            ownedSkins = { usp_default = true },
            equippedSkinId = "usp_default",
            lookSensitivity = 1.4,
            crosshairId = "dot",
            firstSessionComplete = true,
        })
        expect(payload.wins).toEqual(3)
        expect(payload.losses).toEqual(1)
        expect(payload.equippedSkinId).toEqual("usp_default")
        expect(payload.lookSensitivity).toEqual(1.4)
        expect(payload.crosshairId).toEqual("dot")
        expect(#payload.ownedSkinIds).toEqual(1)
        expect(payload.ownedSkinIds[1]).toEqual("usp_default")
    end,
}
