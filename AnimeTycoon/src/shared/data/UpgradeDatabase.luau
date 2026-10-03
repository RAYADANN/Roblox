--!strict
-- Upgrade catalog: Base / Pad / Pad Upgrade / Luck / Cash / Time / Speed.

local ProductIds
if script and script.Parent then
    ProductIds = require(script.Parent.ProductIds)
else
    ProductIds = require("./ProductIds")
end

export type UpgradeId = "base" | "pad" | "padTier" | "luck" | "cash" | "time" | "speed"

export type UpgradeEntry = {
    id: UpgradeId,
    title: string,
    description: string,
    icon: string,
    baseCost: number,
    --- Per-level exponent. Nil uses Constants.UPGRADE_COST_MULT.
    costGrowth: number?,
    maxLevel: number,
    robuxCost: number,
    --- ProductIds key for Robux level-up DevProduct.
    productKey: string,
    productId: number,
    statusAtLevel: (level: number) -> string,
}

local function baseStatus(level: number): string
    return string.format("Current: %d slots", 10 + level)
end

local function padStatus(level: number): string
    return string.format("Current: %d pads", 1 + level)
end

local function padTierStatus(level: number): string
    if level <= 0 then
        return "Current: Tier 1"
    end
    return string.format("Current: Tier %d · +%d%% luck", level + 1, level * 20)
end

local function luckStatus(level: number): string
    return string.format("Current: +%d%%", level * 15)
end

local function cashStatus(level: number): string
    return string.format("Current: +%d%%", level * 10)
end

local function timeStatus(level: number): string
    return string.format("Current: -%d%%", level)
end

local function speedStatus(level: number): string
    local value = 16 + level * 0.5
    if value == math.floor(value) then
        return string.format("Current: %d", value)
    end
    return string.format("Current: %.1f", value)
end

-- Order matches StarterGui + reference screenshots (top → bottom).
local ORDER: { UpgradeId } = { "base", "pad", "padTier", "luck", "cash", "time", "speed" }

local BY_ID: { [UpgradeId]: UpgradeEntry } = {
    base = {
        id = "base",
        title = "Base Expansion",
        description = "Unlock more hero slots",
        icon = "rbxassetid://128535325239533",
        baseCost = 300,
        maxLevel = 20, -- 10 + 20 = 30 slots (3×10 floors)
        robuxCost = 99,
        productKey = "UpgradeBase",
        productId = 0,
        statusAtLevel = baseStatus,
    },
    pad = {
        id = "pad",
        title = "Pad Unlock",
        description = "Unlock another stand pad for offers (buy in order).",
        icon = "rbxassetid://88315691364089",
        baseCost = 750,
        costGrowth = 1.55,
        maxLevel = 4, -- 1 + 4 = 5 pads
        robuxCost = 49,
        productKey = "UpgradePad",
        productId = 0,
        statusAtLevel = padStatus,
    },
    padTier = {
        id = "padTier",
        title = "Pad Upgrade",
        description = "Better pad look +20% luck per level.",
        icon = "rbxassetid://92838046543784",
        baseCost = 1200,
        maxLevel = 3, -- Stand2LVL → Stand3LVL → Stand4LVL
        robuxCost = 79,
        productKey = "UpgradePadTier",
        productId = 0,
        statusAtLevel = padTierStatus,
    },
    luck = {
        id = "luck",
        title = "Luck Boost",
        description = "Better rarity rolls (+15%)",
        icon = "rbxassetid://72922313834491",
        baseCost = 450,
        costGrowth = 1.2,
        maxLevel = 50,
        robuxCost = 29,
        productKey = "UpgradeLuck",
        productId = 0,
        statusAtLevel = luckStatus,
    },
    cash = {
        id = "cash",
        title = "Cash Boost",
        description = "Earn more cash when selling card boxes.",
        icon = "rbxassetid://138510376717252",
        baseCost = 300,
        maxLevel = 20,
        robuxCost = 29,
        productKey = "UpgradeCash",
        productId = 0,
        statusAtLevel = cashStatus,
    },
    time = {
        id = "time",
        title = "Time Boost",
        description = "Reduce pack opening time.",
        icon = "rbxassetid://94005711546618",
        baseCost = 450,
        costGrowth = 1.4,
        maxLevel = 24,
        robuxCost = 19,
        productKey = "UpgradeTime",
        productId = 0,
        statusAtLevel = timeStatus,
    },
    speed = {
        id = "speed",
        title = "Speed Boost",
        description = "Move faster around your plot.",
        icon = "rbxassetid://92881131782708",
        baseCost = 600,
        costGrowth = 1.22,
        maxLevel = 40,
        robuxCost = 19,
        productKey = "UpgradeSpeed",
        productId = 0,
        statusAtLevel = speedStatus,
    },
}

local byProduct: { [number]: UpgradeEntry } = {}

local function refreshProductIndex()
    table.clear(byProduct)
    for _, entry in BY_ID do
        local id = entry.productId
        if typeof(id) == "number" and id > 0 then
            byProduct[id] = entry
        end
    end
end

local function applyProductIds()
    for _, entry in BY_ID do
        local id = (ProductIds :: any)[entry.productKey]
        if typeof(id) == "number" then
            entry.productId = id
        end
    end
    refreshProductIndex()
end

applyProductIds()

local UpgradeDatabase = {}

function UpgradeDatabase.get(id: string): UpgradeEntry?
    return BY_ID[id :: UpgradeId]
end

function UpgradeDatabase.getByProductId(productId: number): UpgradeEntry?
    return byProduct[productId]
end

function UpgradeDatabase.ordered(): { UpgradeEntry }
    local out: { UpgradeEntry } = {}
    for _, id in ORDER do
        table.insert(out, BY_ID[id])
    end
    return out
end

UpgradeDatabase.ORDER = ORDER

return UpgradeDatabase
