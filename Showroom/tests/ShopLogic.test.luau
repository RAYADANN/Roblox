--!strict
local ShopLogic = require("../src/shared/util/ShopLogic")

return {
    ["products include banners and packs"] = function(expect)
        local all = ShopLogic.products({ coins = 0, incomePerSec = 0 })
        expect(#all > 0).toEqual(true)
        local banners = ShopLogic.banners(all)
        local packs = ShopLogic.packs(all)
        expect(#banners).toEqual(2)
        expect(#packs).toEqual(5)
        expect(banners[1].kind).toEqual("banner")
        expect(packs[1].aspectRatio).toBeCloseTo(267 / 323, 0.01)
        expect(packs[1].plateKey).toEqual("CardStandart")
        expect(banners[1].heroKind).toEqual("luck")
        expect(banners[2].heroKind).toEqual("coin")
        expect(banners[2].heroKey).toEqual("ShopCoin")
        expect(packs[1].title).toEqual("+500")
    end,

    ["pack grant scales with wealth"] = function(expect)
        local early = ShopLogic.packGrant(500, { coins = 100, incomePerSec = 5 })
        local late = ShopLogic.packGrant(500, { coins = 1_000_000, incomePerSec = 500 })
        expect(early).toEqual(500)
        expect(late > early).toEqual(true)
        expect(ShopLogic.formatGrant(1500)).toEqual("+1.5K")
    end,
}
