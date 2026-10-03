--!strict

local HeroLevelLogic = require("../src/shared/util/HeroLevelLogic")

return {
    ["level 1 pays the rarity base"] = function(expect)
        expect(HeroLevelLogic.normalize(nil)).toEqual(1)
        expect(HeroLevelLogic.multiplier(1)).toEqual(1)
        expect(HeroLevelLogic.income(5, 1)).toEqual(5)
        expect(HeroLevelLogic.income(70, 1)).toEqual(70)
    end,
    ["every common level increases the payout"] = function(expect)
        local prev = HeroLevelLogic.income(5, 1)
        for level = 1, 49 do
            local nextIncome = HeroLevelLogic.income(5, level + 1)
            expect(nextIncome > prev).toBeTruthy()
            prev = nextIncome
        end
    end,
    ["first common upgrade is cheaper than a second box"] = function(expect)
        local cost = HeroLevelLogic.upgradeCost(5, 4, 1)
        expect(cost).toEqual(11)
    end,
    ["later levels cost more than early ones"] = function(expect)
        local early = HeroLevelLogic.upgradeCost(5, 4, 1) or 0
        local mid = HeroLevelLogic.upgradeCost(5, 4, 10) or 0
        local late = HeroLevelLogic.upgradeCost(5, 4, 40) or 0
        expect(early > 0).toBeTruthy()
        expect(mid > early).toBeTruthy()
        expect(late > mid).toBeTruthy()
    end,
    ["max level has no further cost"] = function(expect)
        expect(HeroLevelLogic.isMax(50)).toBe(true)
        expect(HeroLevelLogic.upgradeCost(5, 4, 50)).toBe(nil)
        expect(HeroLevelLogic.normalize(99)).toEqual(50)
    end,
    ["a maxed common out-earns a fresh mythic"] = function(expect)
        local commonPerSec = HeroLevelLogic.income(5, 50) / 4
        local mythicPerSec = HeroLevelLogic.income(70, 1) / 1.8
        expect(commonPerSec > mythicPerSec).toBeTruthy()
    end,
    ["sync scales an opened hero from its base, not from the current rate"] = function(expect)
        local item = {
            rarity = "common",
            mutations = {},
            baseIncome = 5,
            level = 2,
            incomeRate = 5,
            unpacked = true,
        }
        HeroLevelLogic.syncIncome(item)
        expect(item.level).toEqual(2)
        expect(item.incomeRate).toEqual(HeroLevelLogic.income(5, 2))
        local again = item.incomeRate
        HeroLevelLogic.syncIncome(item)
        expect(item.incomeRate).toEqual(again)
    end,
    ["unknown rarity uses the stored base"] = function(expect)
        local item = {
            rarity = "null",
            mutations = { "prismatic" },
            baseIncome = 100,
            level = 2,
            incomeRate = 1,
            unpacked = true,
        }
        HeroLevelLogic.syncIncome(item)
        expect(item.incomeRate).toEqual(HeroLevelLogic.income(100, 2))
    end,
    ["sealed box is not leveled"] = function(expect)
        local item = {
            rarity = "common",
            mutations = {},
            baseIncome = 5,
            incomeRate = 5,
            unpacked = false,
        }
        HeroLevelLogic.syncIncome(item)
        expect(item.level).toEqual(nil)
        expect(item.incomeRate).toEqual(5)
    end,
}
