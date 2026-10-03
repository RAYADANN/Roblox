--!strict
-- Rarity: unpack duration, income, buy weight. UI must not hardcode seconds.
-- Align with GameAssets.Rarity (Common / Uncommon / Rare / Legendary / Mythic).

export type RarityId = "common" | "uncommon" | "rare" | "legendary" | "mythic"

export type RarityEntry = {
    id: RarityId,
    rank: number,
    unpackDurationSec: number,
    baseIncomePerMini: number,
    produceIntervalSec: number,
    mutationChance: number,
    buyMult: number,
    weight: number,
}

local ById: { [RarityId]: RarityEntry } = {
    common = {
        id = "common",
        rank = 1,
        unpackDurationSec = 12,
        baseIncomePerMini = 5,
        produceIntervalSec = 4,
        mutationChance = 0.35,
        buyMult = 1,
        weight = 48,
    },
    uncommon = {
        id = "uncommon",
        rank = 2,
        unpackDurationSec = 18,
        baseIncomePerMini = 9,
        produceIntervalSec = 3.5,
        mutationChance = 0.45,
        buyMult = 1.6,
        weight = 26,
    },
    rare = {
        id = "rare",
        rank = 3,
        unpackDurationSec = 28,
        baseIncomePerMini = 16,
        produceIntervalSec = 3,
        mutationChance = 0.55,
        buyMult = 2.5,
        weight = 14,
    },
    legendary = {
        id = "legendary",
        rank = 4,
        unpackDurationSec = 48,
        baseIncomePerMini = 40,
        produceIntervalSec = 2.2,
        mutationChance = 0.7,
        buyMult = 5.5,
        weight = 8,
    },
    mythic = {
        id = "mythic",
        rank = 5,
        unpackDurationSec = 60,
        baseIncomePerMini = 70,
        produceIntervalSec = 1.8,
        mutationChance = 0.8,
        buyMult = 9,
        weight = 4,
    },
}

local ORDER: { RarityId } = { "common", "uncommon", "rare", "legendary", "mythic" }

local RarityDatabase = {
    ById = ById,
}

function RarityDatabase.get(rarity: string): RarityEntry?
    return ById[rarity :: RarityId]
end

function RarityDatabase.ordered(): { RarityId }
    return ORDER
end

return RarityDatabase
