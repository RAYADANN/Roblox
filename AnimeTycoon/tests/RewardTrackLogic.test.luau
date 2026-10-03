return {
    ["offsets match 2h track"] = function(expect)
        local RewardTrackDatabase = require("../src/shared/data/RewardTrackDatabase")
        local slots = RewardTrackDatabase.slots()
        expect(#slots).toEqual(12)
        expect(slots[3].rewardType).toEqual("case")
        expect(slots[3].mutation).toEqual("golden")
        expect(slots[5].rewardType).toEqual("money")
        expect(slots[6].mutation).toEqual("diamond")
        expect(slots[10].mutation).toEqual("galaxy")
        expect(slots[11].mutation).toEqual("diamond")
        expect(slots[12].mutation).toEqual("galaxy")
        expect(slots[12].offsetMin).toEqual(120)
    end,
    ["buildItems unlockAt cumulative"] = function(expect)
        local RewardTrackLogic = require("../src/shared/util/RewardTrackLogic")
        local items = RewardTrackLogic.buildItems(1000)
        expect(items[1].unlockAt).toEqual(1000)
        expect(items[2].unlockAt).toEqual(1000 + 5 * 60)
        expect(items[3].caseLabel).toEqual("Golden Case")
        expect(items[3].boxModelName ~= nil).toBeTruthy()
        expect(items[12].unlockAt).toEqual(1000 + 120 * 60)
    end,
}
