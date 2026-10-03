--!strict
local BoostOfferDatabase = require("../src/shared/data/BoostOfferDatabase")
local BoostOfferLogic = require("../src/shared/util/BoostOfferLogic")
local Constants = require("../src/shared/data/Constants")

return {
    ["24h sale window from first view"] = function(expect)
        expect(BoostOfferLogic.durationSec()).toEqual(Constants.BOOST_OFFER_DURATION_SEC)
        expect(BoostOfferLogic.endsAt(0)).toEqual(0)
        expect(BoostOfferLogic.isSaleActive(0, 1_000_000)).toEqual(true)
        expect(BoostOfferLogic.remainingSec(0, 1_000_000)).toEqual(24 * 3600)

        local seen = 1_000_000
        local ends = BoostOfferLogic.endsAt(seen)
        expect(ends).toEqual(seen + 24 * 3600)
        expect(BoostOfferLogic.isSaleActive(seen, seen + 10)).toEqual(true)
        expect(BoostOfferLogic.remainingSec(seen, seen + 3600)).toEqual(23 * 3600)
        expect(BoostOfferLogic.isSaleActive(seen, ends)).toEqual(false)
        expect(BoostOfferLogic.remainingSec(seen, ends + 5)).toEqual(0)
    end,

    ["formatCountdown HH:MM:SS"] = function(expect)
        expect(BoostOfferLogic.formatCountdown(0)).toEqual("00:00:00")
        expect(BoostOfferLogic.formatCountdown(3661)).toEqual("01:01:01")
        expect(BoostOfferLogic.formatCountdown(24 * 3600)).toEqual("24:00:00")
    end,

    ["luck and cash multipliers"] = function(expect)
        expect(BoostOfferLogic.luckMultiplier({})).toEqual(1)
        expect(BoostOfferLogic.luckMultiplier({ ownsLuckyX2 = true })).toEqual(2)
        expect(BoostOfferLogic.luckMultiplier({ ownsLuckyX4 = true })).toEqual(4)
        expect(BoostOfferLogic.luckMultiplier({ ownsLuckyX2 = true, ownsLuckyX4 = true })).toEqual(
            4
        )
        expect(BoostOfferLogic.cashMultiplier({})).toEqual(1)
        expect(BoostOfferLogic.cashMultiplier({ ownsMoneyX2 = true })).toEqual(2)
    end,

    ["availableOffers ignores sale expiry, hides owned"] = function(expect)
        expect(#BoostOfferLogic.availableOffers({})).toEqual(3)
        expect(#BoostOfferLogic.availableOffers({ ownsLuckyX2 = true })).toEqual(2)
        expect(#BoostOfferLogic.availableOffers({
            ownsLuckyX2 = true,
            ownsLuckyX4 = true,
            ownsMoneyX2 = true,
        })).toEqual(0)
    end,

    ["displayPrice sale vs full"] = function(expect)
        local offer = BoostOfferDatabase.get("lucky_x2")
        expect(offer ~= nil).toBeTruthy()
        local onSale = BoostOfferLogic.displayPrice(offer :: any, true)
        expect(onSale.price).toEqual(10)
        expect(onSale.originalPrice).toEqual(49)
        local full = BoostOfferLogic.displayPrice(offer :: any, false)
        expect(full.price).toEqual(49)
        expect(full.originalPrice).toEqual(nil)
    end,

    ["catalog sale prices and world models"] = function(expect)
        local lucky = BoostOfferDatabase.get("lucky_x2")
        expect(lucky ~= nil).toBeTruthy()
        expect((lucky :: any).robux).toEqual(10)
        expect((lucky :: any).robuxWas).toEqual(49)
        expect((lucky :: any).worldModelName).toEqual("LuckyX2")
        expect(BoostOfferDatabase.get("money_x2").worldModelName).toEqual("MoneyX2Gold")
    end,
}
