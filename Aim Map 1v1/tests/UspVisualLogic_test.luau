local UspVisualLogic = require("@shared/util/UspVisualLogic")

return {
    ["isGunModelName: studio + runtime names"] = function(expect)
        expect(UspVisualLogic.isGunModelName("USP")).toEqual(true)
        expect(UspVisualLogic.isGunModelName("USP-S Main")).toEqual(true)
        expect(UspVisualLogic.isGunModelName("UPS-S Main")).toEqual(true)
        expect(UspVisualLogic.isGunModelName("USP-S Default")).toEqual(false)
    end,

    ["muzzlePartNames: Shoot is first"] = function(expect)
        local names = UspVisualLogic.muzzlePartNames()
        expect(names[1]).toEqual("Shoot")
        expect(UspVisualLogic.hasAuthoredShoot).toBeTruthy()
    end,
}
