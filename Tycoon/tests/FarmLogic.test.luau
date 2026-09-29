--!strict
local FarmLogic = require("../src/shared/util/FarmLogic")

return {
    ["first unit costs 1"] = function(expect)
        expect(FarmLogic.unitCost(0)).toEqual(1)
    end,

    ["processPerSec front-loads then +10%"] = function(expect)
        expect(FarmLogic.processPerSec(0)).toEqual(2)
        -- Early: +1/sec floor (not +0.2)
        expect(FarmLogic.processUpgradeDelta(0)).toEqual(1)
        expect(FarmLogic.processPerSec(1)).toEqual(3)
        expect(FarmLogic.processUpgradeDelta(1)).toEqual(1)
        expect(FarmLogic.processPerSec(2)).toEqual(4)
        -- Once rate ≥ 10, delta is 10% of current
        local level = 0
        local rate = FarmLogic.processPerSec(0)
        while rate < 10 do
            level += 1
            rate = FarmLogic.processPerSec(level)
        end
        expect(rate >= 10).toEqual(true)
        expect(FarmLogic.processUpgradeDelta(level)).toBeCloseTo(rate * 0.1, 1e-6)
    end,

    ["early unit costs stay cheap under flat curve"] = function(expect)
        expect(FarmLogic.unitCost(10)).toEqual(1)
        expect(FarmLogic.unitCost(20)).toEqual(2)
        expect(FarmLogic.unitCost(39)).toEqual(6)
    end,

    ["Buy 100 from zero is 100× single price"] = function(expect)
        local unit = FarmLogic.unitCost(0)
        expect(FarmLogic.batchCost(0, 100)).toEqual(unit * 100)
        expect(FarmLogic.batchCost(0, 100)).toEqual(100)
    end,

    ["Buy 25 from zero is 25× single price"] = function(expect)
        expect(FarmLogic.batchCost(0, 25)).toEqual(25)
    end,

    ["batch cost is qty × current unit price"] = function(expect)
        local unit = FarmLogic.unitCost(0)
        expect(FarmLogic.batchCost(0, 1)).toEqual(unit)
        expect(FarmLogic.batchCost(0, 5)).toEqual(unit * 5)
        expect(FarmLogic.batchCost(0, 25)).toEqual(unit * 25)
        expect(FarmLogic.batchCost(0, 100)).toEqual(unit * 100)
        local later = FarmLogic.unitCost(20)
        expect(FarmLogic.batchCost(20, 5)).toEqual(later * 5)
    end,

    ["cannot buy without slots when merge cannot free space"] = function(expect)
        -- No matching triples even after adding a tier-1 — stays over capacity.
        local full = { 1, 2, 3, 4, 5, 6 }
        local ok, err = FarmLogic.canBuy(full, 1, 9999, 0, 6)
        expect(ok).toEqual(false)
        expect(err).toEqual("no_slots")
    end,

    ["Buy 100 fits empty 40-slot plot via auto-merge"] = function(expect)
        expect(FarmLogic.wouldFitAfterBuy({}, 100, 40)).toEqual(true)
        local ok, err = FarmLogic.canBuy({}, 100, 99999, 0, 40)
        expect(ok).toEqual(true)
        expect(err).toEqual(nil)
    end,

    ["cannot buy without coins"] = function(expect)
        local ok, err = FarmLogic.canBuy({}, 1, 0, 0, 48)
        expect(ok).toEqual(false)
        expect(err).toEqual("no_coins")
    end,

    ["emptySlots uses plot capacity"] = function(expect)
        expect(FarmLogic.emptySlots(2, 6)).toEqual(4)
        expect(FarmLogic.emptySlots(6, 6)).toEqual(0)
    end,

    ["applyBuy appends buy-tier units"] = function(expect)
        local units = FarmLogic.applyBuy({ 2 }, 2, 0)
        expect(#units).toEqual(3)
        expect(units[1]).toEqual(2)
        expect(units[2]).toEqual(1)
        expect(units[3]).toEqual(1)
        local upgraded = FarmLogic.applyBuy({}, 2, 1)
        expect(upgraded[1]).toEqual(2)
        expect(upgraded[2]).toEqual(2)
    end,

    ["production upgrade gates: rebirth + summons 100/150"] = function(expect)
        expect(FarmLogic.buyTier(0)).toEqual(1)
        expect(FarmLogic.buyTier(2)).toEqual(3)
        expect(FarmLogic.productionSummonNeed(0)).toEqual(100)
        expect(FarmLogic.productionSummonNeed(1)).toEqual(150)
        expect(FarmLogic.productionSummonNeed(2)).toEqual(200)
        local ok, err = FarmLogic.canUpgradeProduction(0, 0, 999, 9999)
        expect(ok).toEqual(false)
        expect(err).toEqual("need_rebirth")
        ok, err = FarmLogic.canUpgradeProduction(0, 1, 50, 9999)
        expect(ok).toEqual(false)
        expect(err).toEqual("need_summons")
        ok, err = FarmLogic.canUpgradeProduction(0, 1, 100, 0)
        expect(ok).toEqual(false)
        expect(err).toEqual("no_coins")
        ok, err = FarmLogic.canUpgradeProduction(0, 1, 100, 9999)
        expect(ok).toEqual(true)
        expect(err).toEqual(nil)
        -- One rebirth → only one upgrade (level 1 locked until rebirth 2)
        ok, err = FarmLogic.canUpgradeProduction(1, 1, 999, 9999)
        expect(ok).toEqual(false)
        expect(err).toEqual("need_rebirth")
        expect(FarmLogic.productionUpgradeProgress(50, 0)).toBeCloseTo(0.5, 1e-9)
    end,

    ["merge three matching into next tier"] = function(expect)
        local tier = FarmLogic.mergeTier({ 1, 1, 1, 2 })
        expect(tier).toEqual(1)
        local merged = FarmLogic.applyMerge({ 1, 1, 1, 2 }, 1)
        expect(merged ~= nil).toEqual(true)
        if merged then
            expect(#merged).toEqual(2)
            expect(merged[1]).toEqual(2)
            expect(merged[2]).toEqual(2)
        end
    end,

    ["higher tiers stay at the front after merge"] = function(expect)
        local merged = FarmLogic.applyMerge({ 1, 1, 1, 5 }, 1)
        expect(merged ~= nil).toEqual(true)
        if merged then
            expect(merged[1]).toEqual(5)
            expect(merged[2]).toEqual(2)
        end
    end,

    ["mergeAll merges every group and cascades"] = function(expect)
        local six = FarmLogic.mergeAll({ 1, 1, 1, 1, 1, 1 })
        expect(six ~= nil).toEqual(true)
        if six then
            expect(#six).toEqual(2)
            expect(six[1]).toEqual(2)
            expect(six[2]).toEqual(2)
        end

        local nine = FarmLogic.mergeAll({ 1, 1, 1, 1, 1, 1, 1, 1, 1 })
        expect(nine ~= nil).toEqual(true)
        if nine then
            expect(#nine).toEqual(1)
            expect(nine[1]).toEqual(3)
        end

        local mixed = FarmLogic.mergeAll({ 1, 1, 1, 2, 2, 2, 4 })
        expect(mixed ~= nil).toEqual(true)
        if mixed then
            -- 3×1→2, then 4×2→3 + leftover 2 → {4, 3, 2}
            expect(#mixed).toEqual(3)
            expect(mixed[1]).toEqual(4)
            expect(mixed[2]).toEqual(3)
            expect(mixed[3]).toEqual(2)
        end
    end,

    ["autoMergeIfFull noops when not full"] = function(expect)
        expect(FarmLogic.autoMergeIfFull({ 1, 1, 1 }, 6)).toEqual(nil)
    end,

    ["autoMergeIfFull noops when full without triples"] = function(expect)
        expect(FarmLogic.autoMergeIfFull({ 1, 1, 2, 2, 3, 4 }, 6)).toEqual(nil)
    end,

    ["autoMergeIfFull merges when slots are full"] = function(expect)
        local full = { 1, 1, 1, 1, 1, 1 }
        local auto = FarmLogic.autoMergeIfFull(full, 6)
        expect(auto ~= nil).toEqual(true)
        if auto then
            expect(#auto).toEqual(2)
            expect(auto[1]).toEqual(2)
            expect(auto[2]).toEqual(2)
        end
        -- Same result as Merge pad mergeAll when full + mergeable.
        local pad = FarmLogic.mergeAll(full)
        expect(pad ~= nil).toEqual(true)
        if auto and pad then
            expect(#auto).toEqual(#pad)
            expect(auto[1]).toEqual(pad[1])
            expect(auto[2]).toEqual(pad[2])
        end
    end,

    ["autoMergeIfFull frees slots from a packed board"] = function(expect)
        -- 40× tier-1 fills MAX_SLOTS; mergeAll cascades until no triples remain.
        local packed: { number } = {}
        for _ = 1, 40 do
            table.insert(packed, 1)
        end
        local auto = FarmLogic.autoMergeIfFull(packed, 40)
        expect(auto ~= nil).toEqual(true)
        if auto then
            expect(#auto < 40).toEqual(true)
            expect(FarmLogic.mergeTier(auto)).toEqual(nil)
        end
    end,

    ["sortUnitsDesc orders high to low"] = function(expect)
        local sorted = FarmLogic.sortUnitsDesc({ 1, 4, 2, 4 })
        expect(sorted[1]).toEqual(4)
        expect(sorted[2]).toEqual(4)
        expect(sorted[3]).toEqual(2)
        expect(sorted[4]).toEqual(1)
    end,

    ["merge fails without three"] = function(expect)
        expect(FarmLogic.mergeTier({ 1, 1, 2 })).toEqual(nil)
        expect(FarmLogic.applyMerge({ 1, 1 }, 1)).toEqual(nil)
    end,

    ["diamond is 10x dummy base; doubleItems doubles"] = function(expect)
        expect(FarmLogic.dropValue("diamond", false, 1)).toEqual(100)
        expect(FarmLogic.dropValue("diamond", true, 1)).toEqual(200)
    end,

    ["lucky drops add no egg value"] = function(expect)
        expect(FarmLogic.dropValue("lucky", true, 8)).toEqual(0)
    end,

    ["dummy level doubles drop cash"] = function(expect)
        expect(FarmLogic.tierBaseValue(1)).toEqual(10)
        expect(FarmLogic.dropValue("normal", false, 1)).toEqual(10)
        expect(FarmLogic.dropValue("normal", false, 2)).toEqual(20)
        expect(FarmLogic.dropValue("normal", false, 5)).toEqual(160)
        expect(FarmLogic.dropValue("gold", false, 3)).toEqual(120)
    end,

    ["process tick converts queue to cash"] = function(expect)
        local cash, rest = FarmLogic.processTick(10, 2, 1)
        expect(cash).toEqual(2)
        expect(rest).toEqual(8)
    end,

    ["deposit applies multiplier"] = function(expect)
        expect(FarmLogic.depositAmount(20, 1.5)).toEqual(30)
        expect(FarmLogic.depositAmount(0, 1.5)).toEqual(0)
    end,

    ["cashFromEggs uses rebirth cash multiplier"] = function(expect)
        expect(FarmLogic.cashFromEggs(4, 0)).toEqual(4)
        expect(FarmLogic.cashFromEggs(4, 1)).toEqual(8)
    end,

    ["multiplier index stays in 0.5–1.5"] = function(expect)
        expect(FarmLogic.multiplierFromIndex(0)).toEqual(0.5)
        expect(FarmLogic.clampMultiplier(3)).toEqual(1.5)
        expect(FarmLogic.clampMultiplier(0)).toEqual(0.5)
    end,

    ["offline eggs cap and scale with units"] = function(expect)
        expect(FarmLogic.offlineEggs({}, 1000, 0, false)).toEqual(0)
        local one = FarmLogic.offlineEggs({ 1 }, 6, 0, false)
        expect(one >= 10).toEqual(true)
        local high = FarmLogic.offlineEggs({ 5 }, 6, 0, false)
        expect(high > one).toEqual(true)
    end,

    ["drop spawn offset goes into trough (-Look / local -Z)"] = function(expect)
        local mid = FarmLogic.dropSpawnLocalOffset(0.5, 0)
        expect(mid.x).toEqual(0)
        expect(mid.z < 0).toEqual(true)
        expect(mid.y < 0).toEqual(true)
    end,

    ["conveyor velocity follows flat look"] = function(expect)
        local v = FarmLogic.conveyorVelocity(0, 1, 10)
        expect(v.y).toEqual(0)
        expect(math.abs(v.z - 10) < 1e-4).toEqual(true)
        expect(v.x).toEqual(0)
    end,

    ["auto collect zone is tip proximity not spawn"] = function(expect)
        expect(FarmLogic.isInAutoCollectZone(0, 0, 0, 0, 0, 0, 10)).toEqual(true)
        expect(FarmLogic.isInAutoCollectZone(40, 0, 0, 0, 0, 0, 10)).toEqual(false)
        expect(FarmLogic.isInAutoCollectZone(8, 0, 0, 0, 0, 0, 10)).toEqual(true)
    end,
}
