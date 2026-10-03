return {
    ["toInventory clears placement fields"] = function(expect)
        local Logic = require("../src/shared/util/ContainerPlacementLogic")
        local item = {
            placedAt = 100,
            slotIndex = 3,
            unpackProgress = 1,
            unpacked = true,
            incomeRate = 8,
        }
        Logic.toInventory(item)
        expect(item.placedAt).toEqual(nil)
        expect(item.slotIndex).toEqual(nil)
        expect(item.unpacked).toEqual(true)
        expect(item.unpackProgress).toEqual(1)
        expect(item.incomeRate).toEqual(8)
    end,
    ["applyPlace preserves unpacked hero"] = function(expect)
        local Logic = require("../src/shared/util/ContainerPlacementLogic")
        local item = {
            placedAt = nil,
            slotIndex = nil,
            unpackProgress = 1,
            unpacked = true,
            incomeRate = 12,
        }
        Logic.applyPlace(item, 5, 999)
        expect(item.placedAt).toEqual(999)
        expect(item.slotIndex).toEqual(5)
        expect(item.unpacked).toEqual(true)
        expect(item.unpackProgress).toEqual(1)
        expect(item.incomeRate).toEqual(12)
    end,
    ["applyPlace resets sealed box"] = function(expect)
        local Logic = require("../src/shared/util/ContainerPlacementLogic")
        local item = {
            placedAt = nil,
            slotIndex = nil,
            unpackProgress = 0.4,
            unpacked = false,
            incomeRate = 5,
        }
        Logic.applyPlace(item, 2, 50)
        expect(item.placedAt).toEqual(50)
        expect(item.slotIndex).toEqual(2)
        expect(item.unpacked).toEqual(false)
        expect(item.unpackProgress).toEqual(0)
    end,
    ["canPickup requires unpacked and space"] = function(expect)
        local Logic = require("../src/shared/util/ContainerPlacementLogic")
        local ok, err = Logic.canPickup(false, 0, 20)
        expect(ok).toEqual(false)
        expect(err).toEqual("not_unpacked")
        ok, err = Logic.canPickup(true, 20, 20)
        expect(ok).toEqual(false)
        expect(err).toEqual("inventory_full")
        ok, err = Logic.canPickup(true, 3, 20)
        expect(ok).toEqual(true)
        expect(err).toBeFalsy()
    end,
}
