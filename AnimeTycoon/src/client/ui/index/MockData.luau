--!strict

local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

local MockData = {}

function MockData.tabs(): { types.IndexTab }
    return {
        { id = "normal", label = "Normal" },
        { id = "golden", label = "Golden" },
        { id = "diamond", label = "Diamond" },
        { id = "galaxy", label = "Galaxy" },
        { id = "secret", label = "Secret" },
    }
end

function MockData.tabImage(tier: types.IndexTier): string
    if tier == "golden" then
        return assets.tabGolden
    elseif tier == "diamond" then
        return assets.tabDiamond
    elseif tier == "galaxy" then
        return assets.tabGalaxy
    elseif tier == "secret" then
        return assets.tabSecret
    end
    return assets.tabNormal
end

function MockData.cardImage(tier: types.IndexTier): string
    if tier == "golden" then
        return assets.cardGolden
    elseif tier == "diamond" then
        return assets.cardDiamond
    elseif tier == "galaxy" then
        return assets.cardGalaxy
    elseif tier == "secret" then
        return assets.cardSecret
    end
    return assets.cardNormal
end

local TIER_META: {
    [types.IndexTier]: {
        prefix: string,
        mutation: string,
        rares: { string },
        values: { string },
        count: number,
    },
} =
    {
        normal = {
            prefix = "Toy",
            mutation = "None",
            rares = { "Common", "Uncommon", "Common", "Uncommon" },
            values = { "$100/Toy", "$250/Toy", "$400/Toy", "$600/Toy" },
            count = 10,
        },
        golden = {
            prefix = "Gold",
            mutation = "Golden",
            rares = { "Rare", "Rare", "Epic", "Rare" },
            values = { "$1.2K/Toy", "$2K/Toy", "$3.5K/Toy", "$5K/Toy" },
            count = 10,
        },
        diamond = {
            prefix = "Crystal",
            mutation = "Diamond",
            rares = { "Epic", "Epic", "Legendary", "Epic" },
            values = { "$8K/Toy", "$12K/Toy", "$18K/Toy", "$25K/Toy" },
            count = 10,
        },
        galaxy = {
            prefix = "Nebula",
            mutation = "Galaxy",
            rares = { "Legendary", "Legendary", "Mythic", "Legendary" },
            values = { "$40K/Toy", "$55K/Toy", "$70K/Toy", "$90K/Toy" },
            count = 10,
        },
        secret = {
            prefix = "Void",
            mutation = "Secret",
            rares = { "Secret", "Secret", "Secret", "Secret" },
            values = { "$100K/Toy", "$150K/Toy", "$200K/Toy", "$300K/Toy" },
            count = 10,
        },
    }

local SUFFIXES = { "Bot", "Pup", "Drone", "Cube", "Pet", "Core", "Unit", "Buddy", "Orb", "Kit" }

function MockData.items(): { types.IndexItem }
    local list: { types.IndexItem } = {}
    for _, tier in { "normal", "golden", "diamond", "galaxy", "secret" } :: { types.IndexTier } do
        local meta = TIER_META[tier]
        for i = 1, meta.count do
            local unlocked = i <= 4
            table.insert(list, {
                id = string.sub(tier, 1, 1) .. tostring(i),
                name = `{meta.prefix} {SUFFIXES[((i - 1) % #SUFFIXES) + 1]}`,
                valueText = meta.values[((i - 1) % #meta.values) + 1],
                mutationText = meta.mutation,
                rareText = meta.rares[((i - 1) % #meta.rares) + 1],
                tier = tier,
                unlocked = unlocked,
            })
        end
    end
    return list
end

return MockData
