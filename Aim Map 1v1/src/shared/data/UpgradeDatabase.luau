--!strict

export type UpgradeId = "pickaxe" | "backpack"

export type UpgradeEntry = {
    baseCost: number,
    maxLevel: number,
}

local UpgradeDatabase: { [UpgradeId]: UpgradeEntry } = {
    pickaxe = { baseCost = 100, maxLevel = 50 },
    backpack = { baseCost = 150, maxLevel = 30 },
}

return UpgradeDatabase
