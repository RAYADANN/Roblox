return {
    ["maps player data to hud with offers"] = function(expect)
        local buildHudPayload = require("../src/shared/util/buildHudPayload")
        local payload = buildHudPayload.fromPlayerData({
            coins = 500,
            rebirths = 2,
            upgrades = { pickaxe = 3 },
            slots = {},
            inventory = {},
            handUid = nil,
            offers = {
                {
                    uid = "a",
                    templateId = "box1",
                    boxModelName = "Box1",
                    rarity = "common",
                    heroId = "Tanjiro",
                    displayName = "Toy Crate",
                    baseIncome = 5,
                    mutations = { "golden" },
                },
            },
            offersGeneratedAt = 1,
            firstSessionComplete = true,
        })
        expect(payload.coins).toEqual(500)
        expect(payload.rebirths).toEqual(2)
        expect(payload.upgrades.pickaxe).toEqual(3)
        expect(payload.offers[1].displayName).toEqual("Toy Crate")
        expect(payload.offers[1].mutationLabel).toEqual("Golden")
        expect(payload.offers[1].buyPrice > 0).toBeTruthy()
    end,
}
