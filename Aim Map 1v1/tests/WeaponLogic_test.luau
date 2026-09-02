local WeaponLogic = require("@shared/util/WeaponLogic")

return {
    ["head is lethal at full hp"] = function(expect)
        local dmg = WeaponLogic.damageForZone("head")
        local hp = WeaponLogic.applyDamage(100, dmg)
        expect(WeaponLogic.isLethal(hp)).toEqual(true)
    end,

    ["body needs multiple hits"] = function(expect)
        local dmg = WeaponLogic.damageForZone("body")
        local hp = WeaponLogic.applyDamage(100, dmg)
        expect(WeaponLogic.isLethal(hp)).toEqual(false)
        hp = WeaponLogic.applyDamage(hp, dmg)
        expect(WeaponLogic.isLethal(hp)).toEqual(false)
        hp = WeaponLogic.applyDamage(hp, dmg)
        expect(WeaponLogic.isLethal(hp)).toEqual(true)
    end,

    ["range and origin sanity"] = function(expect)
        expect(WeaponLogic.isInRange(10)).toEqual(true)
        expect(WeaponLogic.isInRange(9999)).toEqual(false)
        expect(WeaponLogic.isOriginSane(2)).toEqual(true)
        expect(WeaponLogic.isOriginSane(50)).toEqual(false)
        expect(WeaponLogic.directionMagnitudeOk(1)).toEqual(true)
        expect(WeaponLogic.directionMagnitudeOk(0)).toEqual(false)
    end,

    ["zoneFromPart"] = function(expect)
        expect(WeaponLogic.zoneFromPart("Head")).toEqual("head")
        expect(WeaponLogic.zoneFromPart("UpperTorso")).toEqual("body")
    end,
}
