return {
    ["maps player data to hud with offers"] = function(expect)
        local buildHudPayload = require("../src/shared/util/buildHudPayload")
        local payload = buildHudPayload.fromPlayerData({
            coins = 500,
            rebirths = 2,
            upgrades = { cash = 3 },
            slots = {},
            inventory = {},
            handUid = nil,
            offers = {
                {
                    uid = "a",
                    templateId = "box1",
                    boxModelName = "Box1_MintIce",
                    rarity = "common",
                    heroId = "Tanjiro",
                    displayName = "Tanjiro",
                    baseIncome = 5,
                    mutations = { "golden" },
                },
            },
            offersGeneratedAt = 1,
            firstSessionComplete = true,
            tutorialCompleted = false,
            activeSellBox = { coins = 0, depositCount = 0 },
            sellCrates = {},
            indexFound = { "Tanjiro:golden" },
            boostOfferSeenAt = 0,
            ownsLuckyX2 = false,
            ownsLuckyX4 = false,
            ownsMoneyX2 = false,
            lastSeenAt = 0,
            pendingOfflineCoins = 0,
            firstContainerBought = true,
        })
        expect(payload.coins).toEqual(500)
        expect(payload.rebirths).toEqual(2)
        expect(payload.upgrades.cash).toEqual(3)
        expect(payload.offers[1].displayName).toEqual("Menta Gelato")
        expect(payload.offers[1].mutationLabel).toEqual("Golden")
        expect(payload.offers[1].buyPrice > 0).toBeTruthy()
        expect(payload.sellBoxCoins).toEqual(0)
        expect(payload.sellBoxDeposits).toEqual(0)
        expect(#payload.indexFound).toEqual(1)
        expect(payload.indexFound[1]).toEqual("Tanjiro:golden")
        expect(payload.pendingOfflineCoins).toEqual(0)
    end,
}
