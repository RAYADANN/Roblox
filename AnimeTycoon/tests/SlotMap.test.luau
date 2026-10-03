return {
    ["normalize migrates numeric array holes"] = function(expect)
        local SlotMap = require("../src/shared/util/SlotMap")
        local raw = {
            [3] = {
                uid = "a",
                templateId = "stand1",
                slotIndex = 3,
                unpacked = false,
                unpackProgress = 0,
            },
        }
        local slots = SlotMap.normalize(raw)
        expect(SlotMap.get(slots, 1)).toEqual(nil)
        expect(SlotMap.get(slots, 3).uid).toEqual("a")
        expect(slots["3"].uid).toEqual("a")
        expect(slots[3]).toEqual(nil)
    end,
    ["set writes string keys only"] = function(expect)
        local SlotMap = require("../src/shared/util/SlotMap")
        local slots = SlotMap.empty()
        SlotMap.set(slots, 5, { uid = "hero", slotIndex = 1 })
        expect(slots["5"].uid).toEqual("hero")
        expect(slots["5"].slotIndex).toEqual(5)
        expect(slots[5]).toEqual(nil)
        SlotMap.set(slots, 5, nil)
        expect(SlotMap.get(slots, 5)).toEqual(nil)
    end,
    ["hasAny / toList"] = function(expect)
        local SlotMap = require("../src/shared/util/SlotMap")
        local slots = SlotMap.empty()
        expect(SlotMap.hasAny(slots)).toEqual(false)
        SlotMap.set(slots, 2, { uid = "x", unpacked = true })
        expect(SlotMap.hasAny(slots)).toEqual(true)
        local list = SlotMap.toList(slots)
        expect(#list).toEqual(1)
        expect(list[1].uid).toEqual("x")
    end,
}
