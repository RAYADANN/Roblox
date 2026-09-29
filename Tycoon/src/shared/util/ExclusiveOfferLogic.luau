--!strict
-- Exclusive offer window: 72h from first view. CI-tested (Lune).

local Constants
local ProductIds
local RebirthLogic
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
    ProductIds = require(script.Parent.Parent.data.ProductIds)
    RebirthLogic = require(script.Parent.RebirthLogic)
else
    Constants = require("../data/Constants")
    ProductIds = require("../data/ProductIds")
    RebirthLogic = require("./RebirthLogic")
end

local ExclusiveOfferLogic = {}

function ExclusiveOfferLogic.durationSec(): number
    return Constants.EXCLUSIVE_OFFER_DURATION_SEC
end

--- Ends at unix time; 0 = not started (still show, waiting for first view).
function ExclusiveOfferLogic.endsAt(seenAt: number): number
    if seenAt <= 0 then
        return 0
    end
    return seenAt + ExclusiveOfferLogic.durationSec()
end

function ExclusiveOfferLogic.remainingSec(seenAt: number, now: number): number
    if seenAt <= 0 then
        return ExclusiveOfferLogic.durationSec()
    end
    return math.max(0, ExclusiveOfferLogic.endsAt(seenAt) - now)
end

function ExclusiveOfferLogic.isActive(seenAt: number, now: number): boolean
    if seenAt <= 0 then
        return true
    end
    return ExclusiveOfferLogic.remainingSec(seenAt, now) > 0
end

--- HH:MM:SS for the HUD timer.
function ExclusiveOfferLogic.formatCountdown(remainingSec: number): string
    local sec = math.max(0, math.floor(remainingSec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function ExclusiveOfferLogic.pinkProductId(): number
    return ProductIds.ExclusivePink
end

function ExclusiveOfferLogic.isPinkProduct(productId: number): boolean
    local id = ExclusiveOfferLogic.pinkProductId()
    return typeof(productId) == "number" and productId == id and id > 0
end

function ExclusiveOfferLogic.rebirthProductId(): number
    return ProductIds.ExclusiveRebirthCoins
end

function ExclusiveOfferLogic.isRebirthProduct(productId: number): boolean
    local id = ExclusiveOfferLogic.rebirthProductId()
    return typeof(productId) == "number" and productId == id and id > 0
end

--- After pack rebirth, bonus = half the cash needed for the *next* rebirth.
function ExclusiveOfferLogic.rebirthPackBonusCoins(rebirthsAfterPack: number): number
    local need = RebirthLogic.cost(rebirthsAfterPack)
    return math.floor(need / 2)
end

return ExclusiveOfferLogic
