--!strict
-- Rarity table: duration, income, NPC crowd range, mutation. UI must not hardcode seconds.

export type RarityId = "common" | "uncommon" | "rare" | "epic" | "legendary"

export type RarityEntry = {
    id: RarityId,
    rank: number,
    evolveDurationSec: number,
    baseIncomePerSec: number,
    incomeMultAtEnd: number,
    npcMin: number,
    npcMax: number,
    npcAvoidChance: number, -- chance nobody approaches this placement
    mutationChance: number, -- expected chance to mutate at least once during growth
    lonelyMutationChance: number, -- expected lonely mutation if NPCs avoid
    sellMult: number,
    weight: number,
}

local RarityDatabase: { [RarityId]: RarityEntry } = {
    common = {
        id = "common",
        rank = 1,
        evolveDurationSec = 25,
        baseIncomePerSec = 5,
        incomeMultAtEnd = 1.5,
        npcMin = 3,
        npcMax = 6,
        npcAvoidChance = 0.22,
        mutationChance = 0.55,
        lonelyMutationChance = 0.55,
        sellMult = 8,
        weight = 50,
    },
    uncommon = {
        id = "uncommon",
        rank = 2,
        evolveDurationSec = 35,
        baseIncomePerSec = 8,
        incomeMultAtEnd = 1.8,
        npcMin = 4,
        npcMax = 8,
        npcAvoidChance = 0.16,
        mutationChance = 0.70,
        lonelyMutationChance = 0.60,
        sellMult = 12,
        weight = 28,
    },
    rare = {
        id = "rare",
        rank = 3,
        evolveDurationSec = 50,
        baseIncomePerSec = 14,
        incomeMultAtEnd = 2.2,
        npcMin = 6,
        npcMax = 10,
        npcAvoidChance = 0.12,
        mutationChance = 0.85,
        lonelyMutationChance = 0.65,
        sellMult = 20,
        weight = 14,
    },
    epic = {
        id = "epic",
        rank = 4,
        evolveDurationSec = 70,
        baseIncomePerSec = 24,
        incomeMultAtEnd = 2.8,
        npcMin = 8,
        npcMax = 14,
        npcAvoidChance = 0.08,
        mutationChance = 0.92,
        lonelyMutationChance = 0.70,
        sellMult = 35,
        weight = 6,
    },
    legendary = {
        id = "legendary",
        rank = 5,
        evolveDurationSec = 90,
        baseIncomePerSec = 40,
        incomeMultAtEnd = 3.5,
        npcMin = 10,
        npcMax = 18,
        npcAvoidChance = 0.05,
        mutationChance = 0.98,
        lonelyMutationChance = 0.75,
        sellMult = 55,
        weight = 2,
    },
}

local ORDER: { RarityId } = { "common", "uncommon", "rare", "epic", "legendary" }

local function get(id: string): RarityEntry?
    return RarityDatabase[id :: RarityId]
end

local function isValid(id: string): boolean
    return get(id) ~= nil
end

return {
    ById = RarityDatabase,
    ORDER = ORDER,
    get = get,
    isValid = isValid,
}
