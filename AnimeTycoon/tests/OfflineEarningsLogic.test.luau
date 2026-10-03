return {
    ["below min returns 0"] = function(expect)
        local OfflineEarningsLogic = require("../src/shared/util/OfflineEarningsLogic")
        local SlotMap = require("../src/shared/util/SlotMap")
        local slots = SlotMap.empty()
        SlotMap.set(slots, 1, {
            unpacked = true,
            rarity = "common",
            incomeRate = 8,
        })
        expect(OfflineEarningsLogic.compute(slots, {}, {}, 30)).toEqual(0)
    end,
    ["accrues from producing slots"] = function(expect)
        local OfflineEarningsLogic = require("../src/shared/util/OfflineEarningsLogic")
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local SlotMap = require("../src/shared/util/SlotMap")
        local slots = SlotMap.empty()
        SlotMap.set(slots, 1, {
            unpacked = true,
            rarity = "common",
            incomeRate = 8,
        })
        local rate = 8 / ContainerLogic.produceInterval("common")
        local earned = OfflineEarningsLogic.compute(slots, {}, {}, 120)
        expect(earned).toEqual(math.floor(rate * 120 + 0.5))
    end,
    ["caps at max sec"] = function(expect)
        local OfflineEarningsLogic = require("../src/shared/util/OfflineEarningsLogic")
        local SlotMap = require("../src/shared/util/SlotMap")
        local slots = SlotMap.empty()
        SlotMap.set(slots, 1, {
            unpacked = true,
            rarity = "common",
            incomeRate = 8,
        })
        local a = OfflineEarningsLogic.compute(slots, {}, {}, OfflineEarningsLogic.maxSec())
        local b = OfflineEarningsLogic.compute(slots, {}, {}, OfflineEarningsLogic.maxSec() * 3)
        expect(a).toEqual(b)
    end,
    ["settleOnJoin keeps pending and advances lastSeenAt"] = function(expect)
        local OfflineEarningsLogic = require("../src/shared/util/OfflineEarningsLogic")
        local SlotMap = require("../src/shared/util/SlotMap")
        local slots = SlotMap.empty()
        SlotMap.set(slots, 1, {
            unpacked = true,
            rarity = "common",
            incomeRate = 8,
        })
        local data = {
            slots = slots,
            upgrades = {},
            lastSeenAt = 1_000,
            pendingOfflineCoins = 0,
        }
        local pending = OfflineEarningsLogic.settleOnJoin(data, 1_000 + 600)
        expect(pending > 0).toBeTruthy()
        expect(data.pendingOfflineCoins).toEqual(pending)
        expect(data.lastSeenAt).toEqual(1_600)
        -- Second join without claim keeps pending, does not re-accrue.
        local again = OfflineEarningsLogic.settleOnJoin(data, 2_000)
        expect(again).toEqual(pending)
        expect(data.lastSeenAt).toEqual(2_000)
    end,
    ["doubleAmount doubles"] = function(expect)
        local OfflineEarningsLogic = require("../src/shared/util/OfflineEarningsLogic")
        expect(OfflineEarningsLogic.doubleAmount(100)).toEqual(200)
    end,
}
