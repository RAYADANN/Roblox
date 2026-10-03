--!strict
-- Mock offers — данные + ассеты из StarterGui-основы.
-- Lucky X2/X4 prices mirror HUD BoostOfferDatabase + sale window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

local BoostOfferDatabase = require(ReplicatedStorage.shared.data.BoostOfferDatabase)
local BoostOfferLogic = require(ReplicatedStorage.shared.util.BoostOfferLogic)

export type BoostsOpts = {
    saleActive: boolean?,
    ownsLuckyX2: boolean?,
    ownsLuckyX4: boolean?,
}

local MockData = {}

function MockData.packs(): { types.PackOffer }
    return {
        {
            id = "royal",
            title = "Royal Pack",
            subtitle = "PREMIUM!",
            badge = "NEW!",
            drops = {
                {
                    id = "r1",
                    name = "A",
                    valueText = "$1.2K/Card",
                    chanceText = "48.5%",
                    rarity = "common",
                },
                {
                    id = "r2",
                    name = "B",
                    valueText = "$4K/Card",
                    chanceText = "30%",
                    rarity = "common",
                },
                {
                    id = "r3",
                    name = "C",
                    valueText = "$12K/Card",
                    chanceText = "15%",
                    rarity = "rare",
                },
                {
                    id = "r4",
                    name = "D",
                    valueText = "$80K/Card",
                    chanceText = "5%",
                    rarity = "legendary",
                },
                {
                    id = "r5",
                    name = "E",
                    valueText = "$1M/Card",
                    chanceText = "1.5%",
                    rarity = "limited",
                },
            },
            buys = {
                { productId = "royal_1", price = 79, label = "1 Pack" },
                { productId = "royal_3", price = 199, label = "3 Pack" },
                {
                    productId = "royal_10",
                    price = 599,
                    originalPrice = 999,
                    label = "10 Pack",
                },
            },
        },
    }
end

function MockData.boosts(opts: BoostsOpts?): { types.BoostOffer }
    local saleActive = if opts and opts.saleActive ~= nil then opts.saleActive == true else true
    local ownsX2 = opts ~= nil and opts.ownsLuckyX2 == true
    local ownsX4 = opts ~= nil and opts.ownsLuckyX4 == true

    local dbX2 = BoostOfferDatabase.get("lucky_x2")
    local dbX4 = BoostOfferDatabase.get("lucky_x4")
    local priceX2 = if dbX2
        then BoostOfferLogic.displayPrice(dbX2, saleActive)
        else { price = 10, originalPrice = 49 :: number? }
    local priceX4 = if dbX4
        then BoostOfferLogic.displayPrice(dbX4, saleActive)
        else { price = 10, originalPrice = 49 :: number? }

    return {
        {
            id = "lucky_x2",
            title = "Super Luck",
            description = "Get 2x more luck on Conveyor Pack",
            multiplierText = "2x",
            image = assets.luckYellowBg,
            iconImage = assets.luckYellowIcon,
            buyVariant = "yellow",
            owned = ownsX2,
            offer = {
                productId = "lucky_x2",
                price = priceX2.price,
                originalPrice = priceX2.originalPrice,
            },
        },
        {
            id = "lucky_x4",
            title = "Ultra Luck",
            description = "Get 4x more luck on Conveyor Pack",
            multiplierText = "4x",
            image = assets.luckPinkBg,
            iconImage = assets.luckPinkIcon,
            buyVariant = "pink",
            owned = ownsX4,
            offer = {
                productId = "lucky_x4",
                price = priceX4.price,
                originalPrice = priceX4.originalPrice,
            },
        },
    }
end

function MockData.cash(): { types.CashOffer }
    return {
        {
            id = "cash_small",
            title = "Small Pack",
            valueText = "+$50,000",
            image = assets.moneyBg,
            iconImage = assets.moneyIcon,
            offer = { productId = "cash_small", price = 9 },
        },
        {
            id = "cash_simple",
            title = "Simple Pack",
            valueText = "+$200,000",
            image = assets.moneyBg,
            iconImage = assets.moneyIcon,
            offer = { productId = "cash_simple", price = 24 },
        },
        {
            id = "cash_medium",
            title = "Medium Pack",
            valueText = "+$1,000,000",
            image = assets.moneyBg,
            iconImage = assets.moneyIcon,
            offer = { productId = "cash_medium", price = 79 },
        },
        {
            id = "cash_large",
            title = "Large Pack",
            valueText = "+$5,000,000",
            image = assets.moneyBg,
            iconImage = assets.moneyIcon,
            offer = { productId = "cash_large", price = 199 },
        },
    }
end

function MockData.gamepasses(): { types.GamepassOffer }
    return {
        {
            id = "mega_pack",
            title = "Mega Pack",
            description = "Limited Collection",
            image = assets.specialPackBg,
            icons = {
                assets.specialPackIcon1,
                assets.specialPackIcon2,
                assets.specialPackIcon3,
            },
            buyVariant = "special",
            offer = { productId = "gp_mega_pack", price = 4500 },
        },
        {
            id = "vip",
            title = "V.I.P",
            accent = Color3.fromRGB(255, 170, 40),
            badge = "BEST SELLER!",
            perks = {
                { text = "-20% Pack Timer" },
                { text = "X1.5 Cash Boost" },
                { text = "VIP Name Tag" },
            },
            offer = { productId = "gp_vip", price = 199 },
        },
        {
            id = "auto_conveyor",
            title = "Auto Conveyor",
            accent = Color3.fromRGB(120, 80, 200),
            badge = "NEW!",
            perks = {
                { text = "Auto Collect Packs" },
                { text = "Never AFK Check" },
            },
            offer = {
                productId = "gp_auto",
                price = 800,
                originalPrice = 1249,
            },
        },
    }
end

return MockData
