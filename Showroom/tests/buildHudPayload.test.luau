--!strict
local PlayerData = require("../src/shared/types/PlayerData")
local buildHudPayload = require("../src/shared/util/buildHudPayload")

return {
    ["maps empty profile"] = function(expect)
        local data = table.clone(PlayerData.TEMPLATE)
        data.slots = PlayerData.emptySlots()
        local hud = buildHudPayload.fromPlayerData(data, 0)
        expect(hud.coins).toEqual(50)
        expect(hud.favoriteBank).toEqual(0)
        expect(#hud.slots).toEqual(6)
        expect(hud.slots[1].occupied).toBeFalsy()
        expect(#hud.offers).toEqual(3)
        expect(hud.offers[1].uid).toEqual("")
    end,
    ["keeps bought offer pad empty by index"] = function(expect)
        local data = table.clone(PlayerData.TEMPLATE)
        data.slots = PlayerData.emptySlots()
        data.offers = {
            [1] = {
                uid = "a",
                templateId = "orb_teal",
                rarity = "common",
                sizeId = "medium",
                styleId = "cube_teal",
                characterId = "calm",
                displayName = "A",
                baseIncome = 5,
                mutations = {},
            },
            [2] = {
                uid = "",
                templateId = "",
                rarity = "common",
                sizeId = "medium",
                styleId = "cube_teal",
                characterId = "calm",
                displayName = "",
                baseIncome = 0,
                mutations = {},
            },
            [3] = {
                uid = "c",
                templateId = "orb_amber",
                rarity = "uncommon",
                sizeId = "large",
                styleId = "cube_amber",
                characterId = "curious",
                displayName = "C",
                baseIncome = 10,
                mutations = {},
            },
        }
        local hud = buildHudPayload.fromPlayerData(data, 0)
        expect(hud.offers[1].uid).toEqual("a")
        expect(hud.offers[2].uid).toEqual("")
        expect(hud.offers[3].uid).toEqual("c")
    end,
}
