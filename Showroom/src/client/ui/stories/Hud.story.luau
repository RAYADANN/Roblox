--!strict
-- Hoarcekat: full Showroom HUD (BalanceChip + bank/income + inventory).
-- Path: ReplicatedStorage.UI.stories.Hud

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.Parent.App)
local HudContext = require(script.Parent.Parent.context.HudContext)
local HudProvider = require(script.Parent.Parent.context.HudProvider)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local mount = require(script.Parent.mount)

local MOCK_HUD: NetTypes.HudSyncPayload = {
    coins = 12500,
    plotId = 1,
    favoriteBank = 340,
    offers = {
        {
            uid = "offer-1",
            templateId = "cube_teal",
            rarity = "common",
            sizeId = "medium",
            displayName = "Teal Cube",
            baseIncome = 5,
            buyPrice = 20,
            mutationLabel = "",
        },
        {
            uid = "offer-2",
            templateId = "cube_amber",
            rarity = "rare",
            sizeId = "large",
            displayName = "Amber Chunk",
            baseIncome = 18,
            buyPrice = 84,
            mutationLabel = "Spark",
        },
    },
    slots = {
        {
            occupied = true,
            uid = "slot-1",
            rarity = "uncommon",
            displayName = "Mint Block",
            progress = 0.65,
            incomeRate = 8.5,
            evolved = false,
            mutated = false,
            mutationLabel = "",
            sellPrice = 40,
        },
        {
            occupied = true,
            uid = "slot-2",
            rarity = "epic",
            displayName = "Violet Core",
            progress = 1,
            incomeRate = 42,
            evolved = true,
            mutated = true,
            mutationLabel = "Spark-Neon",
            sellPrice = 900,
        },
    },
    inventory = {
        {
            uid = "inv-1",
            rarity = "common",
            displayName = "Teal Cube",
            baseIncome = 5,
        },
        {
            uid = "inv-2",
            rarity = "legendary",
            displayName = "Giant Rose",
            baseIncome = 120,
        },
    },
    handUid = "inv-2",
    handName = "Giant Rose",
}

local function StoryApp(): React.Node
    local value: HudContext.HudContextValue = {
        hud = MOCK_HUD,
        pickOffer = function(_uid: string) end,
        placeSlot = function(_slot: number) end,
        removeSlot = function(_slot: number) end,
        sellSlot = function(_slot: number) end,
        refreshOffers = function() end,
        selectHand = function(uid: string)
            print(`[Hud story] selectHand {uid}`)
        end,
    }

    return React.createElement(HudProvider, {
        value = value,
    }, {
        App = React.createElement(App),
    })
end

return mount.screen(React.createElement(StoryApp))
