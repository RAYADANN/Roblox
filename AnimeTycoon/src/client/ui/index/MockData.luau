--!strict
-- Index catalog: tabs + cards from HeroCatalog × mutations (IndexLogic).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formatters = require(script.Parent.Parent.util.Formatters)
local IndexLogic = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("util").IndexLogic)
local MutationDatabase =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("data").MutationDatabase)
local assets = require(script.Parent.assets)
local types = require(script.Parent.types)

local MockData = {}

function MockData.tierOrder(): { types.IndexTier }
    return IndexLogic.tierOrder() :: { types.IndexTier }
end

function MockData.tabs(): { types.IndexTab }
    local tabs: { types.IndexTab } = {}
    for _, id in IndexLogic.tierOrder() do
        if id == "normal" then
            table.insert(tabs, { id = id :: types.IndexTier, label = "Normal" })
        else
            local def = MutationDatabase.get(id)
            table.insert(tabs, {
                id = id :: types.IndexTier,
                label = if def then def.displayName else id,
            })
        end
    end
    return tabs
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
    elseif tier == "prismatic" then
        return assets.tabPrismatic
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
    elseif tier == "prismatic" then
        return assets.cardPrismatic
    end
    return assets.cardNormal
end

export type ItemsOpts = {
    foundKeys: { string }?,
    unlockAll: boolean?,
}

function MockData.items(opts: ItemsOpts?): { types.IndexItem }
    local foundKeys = if opts then opts.foundKeys else nil
    local unlockAll = if opts then opts.unlockAll == true else false
    local entries = IndexLogic.buildEntries(if unlockAll then nil else foundKeys)
    if unlockAll then
        -- Rebuild with every key unlocked for Hoarcekat / preview.
        local allKeys: { string } = {}
        for _, e in entries do
            table.insert(allKeys, e.id)
        end
        entries = IndexLogic.buildEntries(allKeys)
    end

    local list: { types.IndexItem } = {}
    for _, e in entries do
        table.insert(list, {
            id = e.id,
            name = e.name,
            valueText = "$" .. Formatters.shortNumber(e.incomePerMini) .. "/Toy",
            mutationText = e.mutationText,
            rareText = e.rareText,
            tier = e.tier :: types.IndexTier,
            unlocked = e.unlocked,
            heroId = e.heroId,
            rarity = e.rarity,
        })
    end
    return list
end

return MockData
