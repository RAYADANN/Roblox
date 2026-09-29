--!strict
local IndexLogic = require("../src/shared/util/IndexLogic")

return {
    ["egg tabs default domestic"] = function(expect)
        local tabs = IndexLogic.eggTabs(nil)
        expect(#tabs).toEqual(4)
        expect(tabs[1].id).toEqual("domestic")
        expect(tabs[1].selected).toEqual(true)
        expect(tabs[2].selected).toEqual(false)
    end,

    ["base cards unlock from owned evolutions"] = function(expect)
        local locked = IndexLogic.baseCards("domestic", nil)
        expect(#locked).toEqual(2)
        expect(locked[1].unlocked).toEqual(false)
        expect(locked[1].ownedCount).toEqual(0)

        local owned = { cat = true, cat_ember = true }
        local open = IndexLogic.baseCards("domestic", owned)
        expect(open[1].id).toEqual("cat")
        expect(open[1].unlocked).toEqual(true)
        expect(open[1].ownedCount).toEqual(2)
        expect(open[2].unlocked).toEqual(false)
    end,

    ["evolution cards filter owned"] = function(expect)
        local cards = IndexLogic.evolutionCards("cat", { cat = true, cat_frost = true })
        expect(#cards).toEqual(3)
        expect(cards[1].unlocked).toEqual(true)
        expect(cards[2].unlocked).toEqual(false)
        expect(cards[3].unlocked).toEqual(true)
    end,
}
