return {
    ["unpack progress reaches 1"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        expect(ContainerLogic.unpackProgress(0, "common")).toEqual(0)
        expect(ContainerLogic.unpackProgress(12, "common")).toEqual(1)
        expect(ContainerLogic.unpackProgress(6, "common")).toBeCloseTo(0.5, 0.01)
    end,
    ["buy price grows with rarity"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local common = ContainerLogic.buyPrice("common", 0)
        local rare = ContainerLogic.buyPrice("rare", 0)
        expect(rare > common).toBeTruthy()
    end,
    ["mutation boosts income"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local base = ContainerLogic.incomePerMini("common", {})
        local gold = ContainerLogic.incomePerMini("common", { "golden" })
        expect(gold > base).toBeTruthy()
    end,
    ["incomePerSecond uses produce interval"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local perMini = ContainerLogic.incomePerMini("common", {})
        local perSec = ContainerLogic.incomePerSecond("common", {})
        local interval = ContainerLogic.produceInterval("common")
        expect(perSec).toBeCloseTo(perMini / interval, 1e-6)
    end,
    ["totalIncomePerSecond sums unpacked slots"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local sum = ContainerLogic.totalIncomePerSecond({
            { unpacked = true, rarity = "common", incomeRate = 8 },
            { unpacked = false, rarity = "rare", incomeRate = 100 },
            { unpacked = true, rarity = "common", incomeRate = 8 },
        })
        local one = 8 / ContainerLogic.produceInterval("common")
        expect(sum).toBeCloseTo(one * 2, 1e-6)
    end,
    ["unpack remaining reaches 0"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        expect(ContainerLogic.unpackRemainingSec(0, "common")).toEqual(12)
        expect(ContainerLogic.unpackRemainingSec(12, "common")).toEqual(0)
        expect(ContainerLogic.unpackRemainingSec(6, "common")).toEqual(6)
    end,
    ["formatRemaining uses seconds then m:ss"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        expect(ContainerLogic.formatRemaining(12)).toEqual("12s")
        expect(ContainerLogic.formatRemaining(0)).toEqual("0s")
        expect(ContainerLogic.formatRemaining(65)).toEqual("1:05")
    end,
    ["unpackEndsAt = placedAt + duration"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        expect(ContainerLogic.unpackEndsAt(1000, "common")).toEqual(1012)
    end,
    ["fastUnpack always takes 3 seconds"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        expect(ContainerLogic.unpackDuration("legendary", 1, true)).toEqual(3)
        expect(ContainerLogic.unpackProgress(1.5, "legendary", 1, true)).toBeCloseTo(0.5, 0.01)
        expect(ContainerLogic.unpackProgress(3, "common", 1, true)).toEqual(1)
        expect(ContainerLogic.unpackEndsAt(1000, "rare", 1, true)).toEqual(1003)
    end,
}
