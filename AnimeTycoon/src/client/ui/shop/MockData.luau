--!strict
-- Mock offers — данные + ассеты из StarterGui-основы.

local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

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

function MockData.boosts(): { types.BoostOffer }
    return {
        {
            id = "super_luck",
            title = "Super Luck",
            description = "Get 2x more luck on Conveyor Pack",
            multiplierText = "2x",
            image = assets.luckYellowBg,
            iconImage = assets.luckYellowIcon,
            buyVariant = "yellow",
            offer = { productId = "boost_super_luck", price = 1499 },
        },
        {
            id = "ultra_luck",
            title = "Ultra Luck",
            description = "Get 4x more luck on Conveyor Pack",
            multiplierText = "4x",
            image = assets.luckPinkBg,
            iconImage = assets.luckPinkIcon,
            buyVariant = "pink",
            offer = {
                productId = "boost_ultra_luck",
                price = 499,
                originalPrice = 799,
            },
        },
        {
            id = "cash_boost",
            title = "Cash Boost",
            description = "Permanently 2x Cash",
            multiplierText = "2x",
            image = assets.luckYellowBg,
            iconImage = assets.luckYellowIcon,
            buyVariant = "yellow",
            offer = {
                productId = "boost_cash",
                price = 119,
                originalPrice = 249,
            },
        },
        {
            id = "offline_boost",
            title = "Offline Boost",
            description = "Permanently 2x Offline Cash",
            multiplierText = "2x",
            image = assets.luckPinkBg,
            iconImage = assets.luckPinkIcon,
            buyVariant = "pink",
            offer = { productId = "boost_offline", price = 79 },
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
