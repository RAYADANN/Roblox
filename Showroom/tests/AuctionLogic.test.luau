--!strict
local AuctionLogic = require("../src/shared/util/AuctionLogic")

return {
    ["targetValue: Small 1 mut rebirth x1 ≈ 500 (uncommon)"] = function(expect)
        local v = AuctionLogic.targetValue("uncommon", "small", 1, 0)
        expect(v).toEqual(500)
    end,
    ["targetValue: Giant 3 mut rebirth x2 ≈ 4800 (uncommon)"] = function(expect)
        -- rebirths=1 → multiplier 2 when MULT_PER=1
        local v = AuctionLogic.targetValue("uncommon", "giant", 3, 1)
        expect(v).toEqual(4800)
    end,
    ["mutation mult: more stacks → higher"] = function(expect)
        expect(AuctionLogic.mutationValueMult(0) < AuctionLogic.mutationValueMult(1)).toBeTruthy()
        expect(AuctionLogic.mutationValueMult(1) < AuctionLogic.mutationValueMult(2)).toBeTruthy()
        expect(AuctionLogic.mutationValueMult(2) < AuctionLogic.mutationValueMult(3)).toBeTruthy()
    end,
    ["size mult: small < giant"] = function(expect)
        expect(AuctionLogic.sizeValueMult("small") < AuctionLogic.sizeValueMult("giant")).toBeTruthy()
    end,
    ["commission: first free, then 10% / 20%"] = function(expect)
        expect(AuctionLogic.commissionForNextRun(0, 1000)).toEqual(0)
        expect(AuctionLogic.commissionForNextRun(1, 1000)).toEqual(100)
        expect(AuctionLogic.commissionForNextRun(2, 1000)).toEqual(200)
    end,
    ["canStartRun: max 3"] = function(expect)
        expect(AuctionLogic.canStartRun(0)).toBeTruthy()
        expect(AuctionLogic.canStartRun(2)).toBeTruthy()
        expect(AuctionLogic.canStartRun(3)).toBeFalsy()
    end,
    ["generateBids: strictly increasing, ends near target"] = function(expect)
        local bids = AuctionLogic.generateBids(1000, 5, 42)
        expect(#bids >= 3).toBeTruthy()
        for i = 2, #bids do
            expect(bids[i].amount > bids[i - 1].amount).toBeTruthy()
        end
        local last = bids[#bids].amount
        expect(last >= 900).toBeTruthy()
        expect(last <= 1100).toBeTruthy()
    end,
    ["bidCount: clamps 3..7"] = function(expect)
        local lo = AuctionLogic.bidCount("common", "small", 0)
        local hi = AuctionLogic.bidCount("legendary", "giant", 3)
        expect(lo >= 3).toBeTruthy()
        expect(hi <= 7).toBeTruthy()
        expect(hi >= lo).toBeTruthy()
    end,
}
