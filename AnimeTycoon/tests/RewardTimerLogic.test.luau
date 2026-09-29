--!strict
local RewardTimerLogic = require("../src/shared/util/RewardTimerLogic")

return {
    ["remaining: не уходит в минус"] = function(expect)
        expect(RewardTimerLogic.remaining(100, 150)).toEqual(0)
    end,
    ["remaining: ceil до целых секунд"] = function(expect)
        expect(RewardTimerLogic.remaining(10.2, 8)).toEqual(3)
    end,
    ["format: MM:SS"] = function(expect)
        expect(RewardTimerLogic.format(286)).toEqual("04:46")
        expect(RewardTimerLogic.format(0)).toEqual("00:00")
    end,
    ["format: H:MM:SS"] = function(expect)
        expect(RewardTimerLogic.format(4186)).toEqual("1:09:46")
    end,
    ["isClaimable"] = function(expect)
        expect(RewardTimerLogic.isClaimable(false, 0)).toEqual(true)
        expect(RewardTimerLogic.isClaimable(true, 0)).toEqual(false)
        expect(RewardTimerLogic.isClaimable(false, 5)).toEqual(false)
    end,
    ["firstClaimableIndex"] = function(expect)
        local now = 1000
        local items = {
            { claimed = true, unlockAt = 900 },
            { claimed = false, unlockAt = 1000 },
            { claimed = false, unlockAt = 1100 },
        }
        expect(RewardTimerLogic.firstClaimableIndex(items, now)).toEqual(2)
    end,
}
