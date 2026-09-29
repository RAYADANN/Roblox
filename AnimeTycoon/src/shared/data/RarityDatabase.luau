--!strict
-- Rarity: unpack duration, income, buy weight. UI must not hardcode seconds.

export type RarityId = "common" | "uncommon" | "rare" | "epic" | "legendary"

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
        weight = 50,
    },
    uncommon = {
        id = "uncommon",
        rank = 2,
        unpackDurationSec = 18,
        baseIncomePerMini = 9,
        produceIntervalSec = 3.5,
        mutationChance = 0.45,
        buyMult = 1.6,
        weight = 28,
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
    epic = {
        id = "epic",
        rank = 4,
        unpackDurationSec = 40,
        baseIncomePerMini = 28,
        produceIntervalSec = 2.5,
        mutationChance = 0.65,
        buyMult = 4,
        weight = 6,
    },
    legendary = {
        id = "legendary",
        rank = 5,
        unpackDurationSec = 55,
        baseIncomePerMini = 50,
        produceIntervalSec = 2,
        mutationChance = 0.75,
        buyMult = 7,
        weight = 2,
    },
}

local ORDER: { RarityId } = { "common", "uncommon", "rare", "epic", "legendary" }

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
