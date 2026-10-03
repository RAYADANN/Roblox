--!strict
-- Pure: offline income from producing ramp heroes while away.

local BoostOfferLogic
local Constants
local ContainerLogic
local SlotMap
local UpgradeLogic
if script and script.Parent then
    BoostOfferLogic = require(script.Parent.BoostOfferLogic)
    Constants = require(script.Parent.Parent.data.Constants)
    ContainerLogic = require(script.Parent.ContainerLogic)
    SlotMap = require(script.Parent.SlotMap)
    UpgradeLogic = require(script.Parent.UpgradeLogic)
else
    BoostOfferLogic = require("./BoostOfferLogic")
    Constants = require("../data/Constants")
    ContainerLogic = require("./ContainerLogic")
    SlotMap = require("./SlotMap")
    UpgradeLogic = require("./UpgradeLogic")
end

export type BoostOwnership = BoostOfferLogic.BoostOwnership

local OfflineEarningsLogic = {}

function OfflineEarningsLogic.maxSec(): number
    return Constants.OFFLINE_EARNINGS_MAX_SEC
end

function OfflineEarningsLogic.minSec(): number
    return Constants.OFFLINE_EARNINGS_MIN_SEC
end

function OfflineEarningsLogic.coinsPerSecond(
    slots: any,
    upgrades: { [string]: number }?,
    boost: BoostOwnership?
): number
    local list = SlotMap.toList(slots)
    local rate = ContainerLogic.totalIncomePerSecond(list)
    rate *= UpgradeLogic.cashMultiplier(upgrades)
    rate *= BoostOfferLogic.cashMultiplier(boost or {})
    return rate
end

function OfflineEarningsLogic.compute(
    slots: any,
    upgrades: { [string]: number }?,
    boost: BoostOwnership?,
    elapsedSec: number
): number
    local elapsed = math.max(0, elapsedSec)
    if elapsed < OfflineEarningsLogic.minSec() then
        return 0
    end
    local capped = math.min(elapsed, OfflineEarningsLogic.maxSec())
    local rate = OfflineEarningsLogic.coinsPerSecond(slots, upgrades, boost)
    if rate <= 0 then
        return 0
    end
    return math.max(0, math.floor(rate * capped + 0.5))
end

function OfflineEarningsLogic.doubleAmount(current: number): number
    return math.max(0, math.floor(current * 2 + 0.5))
end

--- On join: accrue pending from lastSeenAt if none pending yet. Touches lastSeenAt.
function OfflineEarningsLogic.settleOnJoin(
    data: {
        slots: any,
        upgrades: { [string]: number }?,
        ownsLuckyX2: boolean?,
        ownsLuckyX4: boolean?,
        ownsMoneyX2: boolean?,
        lastSeenAt: number?,
        pendingOfflineCoins: number?,
    },
    now: number
): number
    local pending = math.max(0, tonumber(data.pendingOfflineCoins) or 0)
    local last = math.max(0, tonumber(data.lastSeenAt) or 0)
    if pending <= 0 and last > 0 then
        local elapsed = math.max(0, now - last)
        pending = OfflineEarningsLogic.compute(data.slots, data.upgrades, {
            ownsLuckyX2 = data.ownsLuckyX2,
            ownsLuckyX4 = data.ownsLuckyX4,
            ownsMoneyX2 = data.ownsMoneyX2,
        }, elapsed)
        data.pendingOfflineCoins = pending
    elseif pending < 0 then
        pending = 0
        data.pendingOfflineCoins = 0
    end
    data.lastSeenAt = now
    return pending
end

return OfflineEarningsLogic
