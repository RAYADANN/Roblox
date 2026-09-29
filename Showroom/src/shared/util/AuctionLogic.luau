--!strict
-- Pure auction value / bids / commission. CI-tested.
-- Stand purchase level does NOT affect auction price.

local RarityDatabase
local RebirthLogic
local ExhibitLogic
local Constants
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
    RebirthLogic = require(script.Parent.RebirthLogic)
    ExhibitLogic = require(script.Parent.ExhibitLogic)
    Constants = require(script.Parent.Parent.data.Constants)
else
    RarityDatabase = require("../data/RarityDatabase")
    RebirthLogic = require("./RebirthLogic")
    ExhibitLogic = require("./ExhibitLogic")
    Constants = require("../data/Constants")
end

export type BidStep = {
    buyerName: string,
    amount: number,
}

-- Tuned so uncommon Small +1 mut + rebirth×1 ≈ 500; Giant +3 mut +×2 ≈ 4800.
local RARITY_BASE: { [string]: number } = {
    common = 280,
    uncommon = 400,
    rare = 700,
    epic = 1300,
    legendary = 2500,
}

local SIZE_VALUE_MULT: { [string]: number } = {
    small = 1.0,
    medium = 1.3,
    large = 1.8,
    giant = 2.4,
}

local BUYERS: { string } = {
    "Buyer",
    "Collector",
    "Rarity Hunter",
    "Trader",
    "Patron",
    "Broker",
    "Connoisseur",
}

local AuctionLogic = {}

function AuctionLogic.maxRuns(): number
    return Constants.AUCTION_MAX_RUNS
end

function AuctionLogic.durationSec(): number
    return Constants.AUCTION_DURATION_SEC
end

function AuctionLogic.rarityBase(rarity: string): number
    return RARITY_BASE[rarity] or RARITY_BASE.common
end

function AuctionLogic.sizeValueMult(sizeId: string?): number
    if sizeId and SIZE_VALUE_MULT[sizeId] then
        return SIZE_VALUE_MULT[sizeId]
    end
    return SIZE_VALUE_MULT.medium
end

function AuctionLogic.mutationValueMult(mutationCount: number): number
    local n = math.clamp(math.floor(mutationCount), 0, 3)
    if n <= 0 then
        return 1.0
    elseif n == 1 then
        return 1.25
    elseif n == 2 then
        return 1.75
    end
    return 2.5
end

function AuctionLogic.targetValue(
    rarity: string,
    sizeId: string?,
    mutationCount: number,
    rebirths: number
): number
    local base = AuctionLogic.rarityBase(rarity)
    local sizeM = AuctionLogic.sizeValueMult(sizeId)
    local mutM = AuctionLogic.mutationValueMult(mutationCount)
    local rebirthM = RebirthLogic.valueMultiplier(math.max(0, math.floor(rebirths)))
    return math.max(1, math.floor(base * sizeM * mutM * rebirthM + 0.5))
end

function AuctionLogic.bidCount(rarity: string, sizeId: string?, mutationCount: number): number
    local entry = RarityDatabase.get(rarity)
    local rank = if entry then entry.rank else 1
    local sizeRank = 1
    if sizeId == "medium" then
        sizeRank = 2
    elseif sizeId == "large" then
        sizeRank = 3
    elseif sizeId == "giant" then
        sizeRank = 4
    end
    local mut = math.clamp(math.floor(mutationCount), 0, 3)
    return math.clamp(2 + rank + mut + (sizeRank - 1), 3, 7)
end

-- runsCompleted: auctions already finished for this exhibit (0 before first).
-- Commission charged when starting the *next* run.
function AuctionLogic.commissionForNextRun(runsCompleted: number, lastMaxBid: number): number
    local n = math.floor(runsCompleted)
    local maxRuns = AuctionLogic.maxRuns()
    if n <= 0 then
        return 0
    end
    if n >= maxRuns then
        return 0
    end
    local rate = if n == 1 then 0.10 else 0.20
    return math.max(0, math.floor(lastMaxBid * rate + 0.5))
end

function AuctionLogic.canStartRun(runsCompleted: number): boolean
    return math.floor(runsCompleted) < AuctionLogic.maxRuns()
end

function AuctionLogic.sizeLabel(sizeId: string?): string
    return ExhibitLogic.sizeLabel(sizeId)
end

local function rngFromSeed(seed: number): () -> number
    local state = math.floor(seed) % 2147483647
    if state <= 0 then
        state = 1
    end
    return function()
        state = (state * 48271) % 2147483647
        return state / 2147483647
    end
end

function AuctionLogic.generateBids(targetValue: number, count: number, seed: number): { BidStep }
    local n = math.clamp(math.floor(count), 3, 7)
    local rng = rngFromSeed(seed)
    local final = math.max(1, math.floor(targetValue * (0.92 + 0.16 * rng()) + 0.5))
    local first = math.max(1, math.floor(final * (0.38 + 0.12 * rng()) + 0.5))
    if first >= final then
        first = math.max(1, final - n)
    end

    local amounts: { number } = table.create(n)
    amounts[1] = first
    amounts[n] = final
    for i = 2, n - 1 do
        local t = (i - 1) / (n - 1)
        local ease = t * t -- accelerate toward the end
        local raw = first + (final - first) * ease
        local jitter = (rng() - 0.5) * 0.06 * (final - first)
        amounts[i] = math.floor(raw + jitter + 0.5)
    end

    -- Enforce strictly increasing integers.
    for i = 2, n do
        if amounts[i] <= amounts[i - 1] then
            amounts[i] = amounts[i - 1] + math.max(1, math.floor((final - first) / (n * 4) + 1))
        end
    end
    if amounts[n] < final then
        amounts[n] = final
        for i = n, 2, -1 do
            if amounts[i] <= amounts[i - 1] then
                amounts[i - 1] = amounts[i] - 1
            end
        end
        if amounts[1] < 1 then
            amounts[1] = 1
            for i = 2, n do
                if amounts[i] <= amounts[i - 1] then
                    amounts[i] = amounts[i - 1] + 1
                end
            end
        end
    end

    local bids: { BidStep } = table.create(n)
    for i = 1, n do
        local name = BUYERS[((i - 1) % #BUYERS) + 1]
        bids[i] = { buyerName = name, amount = amounts[i] }
    end
    return bids
end

function AuctionLogic.bidAtElapsed(
    bids: { BidStep },
    elapsedSec: number,
    durationSec: number
): (number, BidStep?)
    if #bids == 0 then
        return 0, nil
    end
    local dur = math.max(0.001, durationSec)
    local t = math.clamp(elapsedSec / dur, 0, 1)
    local idx = math.clamp(math.floor(t * #bids) + 1, 1, #bids)
    if elapsedSec <= 0 then
        return 0, nil
    end
    return idx, bids[idx]
end

function AuctionLogic.remainingSec(endsAt: number, now: number): number
    return math.max(0, endsAt - now)
end

return AuctionLogic
