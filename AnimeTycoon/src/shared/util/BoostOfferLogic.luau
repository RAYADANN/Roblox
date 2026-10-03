--!strict
-- Pure: 24h sale window for boost offers + luck/cash pass multipliers.
-- After sale ends: full price, no timer — offers stay until purchased.

local Constants
local BoostOfferDatabase
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
    BoostOfferDatabase = require(script.Parent.Parent.data.BoostOfferDatabase)
else
    Constants = require("../data/Constants")
    BoostOfferDatabase = require("../data/BoostOfferDatabase")
end

export type BoostOwnership = {
    ownsLuckyX2: boolean?,
    ownsLuckyX4: boolean?,
    ownsMoneyX2: boolean?,
}

export type DisplayPrice = {
    --- Charged / primary robux shown.
    price: number,
    --- Strikethrough “was” (nil when not on sale).
    originalPrice: number?,
}

local BoostOfferLogic = {}

function BoostOfferLogic.durationSec(): number
    return Constants.BOOST_OFFER_DURATION_SEC
end

function BoostOfferLogic.endsAt(seenAt: number): number
    if seenAt <= 0 then
        return 0
    end
    return seenAt + BoostOfferLogic.durationSec()
end

function BoostOfferLogic.remainingSec(seenAt: number, now: number): number
    if seenAt <= 0 then
        return BoostOfferLogic.durationSec()
    end
    return math.max(0, BoostOfferLogic.endsAt(seenAt) - now)
end

--- Sale window still open (discount + timer). Unseen counts as on sale.
function BoostOfferLogic.isSaleActive(seenAt: number, now: number): boolean
    if seenAt <= 0 then
        return true
    end
    return BoostOfferLogic.remainingSec(seenAt, now) > 0
end

--- @deprecated use isSaleActive — sale window, not offer visibility.
function BoostOfferLogic.isActive(seenAt: number, now: number): boolean
    return BoostOfferLogic.isSaleActive(seenAt, now)
end

--- HH:MM:SS for the HUD timer (sale only).
function BoostOfferLogic.formatCountdown(remainingSec: number): string
    local sec = math.max(0, math.floor(remainingSec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function BoostOfferLogic.isOwned(data: BoostOwnership, offerId: string): boolean
    local offer = BoostOfferDatabase.get(offerId)
    if not offer then
        return false
    end
    local field = offer.ownedField
    return (data :: any)[field] == true
end

--- Max luck weight mult from owned passes (X4 supersedes X2).
function BoostOfferLogic.luckMultiplier(data: BoostOwnership): number
    if data.ownsLuckyX4 == true then
        return 4
    end
    if data.ownsLuckyX2 == true then
        return 2
    end
    return 1
end

function BoostOfferLogic.cashMultiplier(data: BoostOwnership): number
    if data.ownsMoneyX2 == true then
        return 2
    end
    return 1
end

--- Unowned offers stay visible forever; sale only changes price/timer.
function BoostOfferLogic.offerAvailable(data: BoostOwnership, offerId: string): boolean
    return not BoostOfferLogic.isOwned(data, offerId)
end

function BoostOfferLogic.availableOffers(data: BoostOwnership): { BoostOfferDatabase.BoostOffer }
    local out = {}
    for _, offer in BoostOfferDatabase.all() do
        if BoostOfferLogic.offerAvailable(data, offer.id) then
            table.insert(out, offer)
        end
    end
    return out
end

function BoostOfferLogic.displayPrice(
    offer: BoostOfferDatabase.BoostOffer,
    saleActive: boolean
): DisplayPrice
    if saleActive then
        return {
            price = offer.robux,
            originalPrice = offer.robuxWas,
        }
    end
    return {
        price = offer.robuxWas,
        originalPrice = nil,
    }
end

function BoostOfferLogic.isBoostProduct(productId: number): boolean
    return BoostOfferDatabase.getByProductId(productId) ~= nil
end

return BoostOfferLogic
