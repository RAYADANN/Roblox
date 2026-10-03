return {
    ["pickFreeIndex returns first hole"] = function(expect)
        local Logic = require("../src/shared/util/BaseClaimLogic")
        expect(Logic.pickFreeIndex({}, 3)).toEqual(1)
        expect(Logic.pickFreeIndex({ [1] = 10 }, 3)).toEqual(2)
        expect(Logic.pickFreeIndex({ [1] = 10, [2] = 20 }, 3)).toEqual(3)
    end,
    ["pickFreeIndex nil when full"] = function(expect)
        local Logic = require("../src/shared/util/BaseClaimLogic")
        expect(Logic.pickFreeIndex({ [1] = 1, [2] = 2, [3] = 3 }, 3)).toEqual(nil)
    end,
    ["releaseUser frees index"] = function(expect)
        local Logic = require("../src/shared/util/BaseClaimLogic")
        local occupied = { [1] = 100, [2] = 200 }
        expect(Logic.releaseUser(occupied, 200)).toEqual(2)
        expect(occupied[2]).toEqual(nil)
        expect(Logic.indexForUser(occupied, 100)).toEqual(1)
        expect(Logic.indexForUser(occupied, 200)).toEqual(nil)
    end,
}
