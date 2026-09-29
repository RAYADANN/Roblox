--!strict
local ExclusiveOfferLogic = require("../src/shared/util/ExclusiveOfferLogic")

return {
    ["72h window from first view"] = function(expect)
        expect(ExclusiveOfferLogic.durationSec()).toEqual(72 * 3600)
        expect(ExclusiveOfferLogic.endsAt(0)).toEqual(0)
        expect(ExclusiveOfferLogic.isActive(0, 1_000_000)).toEqual(true)
        expect(ExclusiveOfferLogic.remainingSec(0, 1_000_000)).toEqual(72 * 3600)

        local seen = 1_000_000
        local ends = ExclusiveOfferLogic.endsAt(seen)
        expect(ends).toEqual(seen + 72 * 3600)
        expect(ExclusiveOfferLogic.isActive(seen, seen + 10)).toEqual(true)
        expect(ExclusiveOfferLogic.remainingSec(seen, seen + 3600)).toEqual(71 * 3600)
        expect(ExclusiveOfferLogic.isActive(seen, ends)).toEqual(false)
        expect(ExclusiveOfferLogic.remainingSec(seen, ends + 5)).toEqual(0)
    end,

    ["formatCountdown HH:MM:SS"] = function(expect)
        expect(ExclusiveOfferLogic.formatCountdown(0)).toEqual("00:00:00")
        expect(ExclusiveOfferLogic.formatCountdown(3661)).toEqual("01:01:01")
        expect(ExclusiveOfferLogic.formatCountdown(72 * 3600)).toEqual("72:00:00")
    end,

    ["pink product id"] = function(expect)
        expect(ExclusiveOfferLogic.pinkProductId()).toEqual(3713062105)
        expect(ExclusiveOfferLogic.isPinkProduct(3713062105)).toEqual(true)
        expect(ExclusiveOfferLogic.isPinkProduct(0)).toEqual(false)
    end,

    ["rebirth pack bonus is half next rebirth cost"] = function(expect)
        -- After pack apply, rebirths=1 → next cost 25000 → bonus 12500.
        expect(ExclusiveOfferLogic.rebirthPackBonusCoins(1)).toEqual(12_500)
        expect(ExclusiveOfferLogic.rebirthPackBonusCoins(2)).toEqual(250_000)
        expect(ExclusiveOfferLogic.rebirthProductId()).toEqual(3713065486)
        expect(ExclusiveOfferLogic.isRebirthProduct(3713065486)).toEqual(true)
        expect(ExclusiveOfferLogic.isRebirthProduct(0)).toEqual(false)
    end,
}
