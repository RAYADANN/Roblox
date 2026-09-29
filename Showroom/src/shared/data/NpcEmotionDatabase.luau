--!strict
-- NPC crowd reactions by rarity + celebrate on mutation. Pure.

export type EmotionSet = { string }

-- More variety so cycling feels alive.
local BY_RARITY: { [string]: EmotionSet } = {
    common = { "…", "ok", "meh", "hmm", "alright", "👀", "eh" },
    uncommon = { "nice!", ":)", "cool", "neat", "huh", "pretty", "ok!" },
    rare = { "WOW!", "ooh!", ":O", "whoa", "shiny", "love?", "!!" },
    epic = { "AMAZING", "!!!", "love it", "🔥", "insane", "whoa!!", "YES" },
    legendary = { "INSANE!!!", "BEST!!", "😍", "NO WAY", "GOAT", "🔥🔥", "LEGEND" },
}

local CELEBRATE: EmotionSet = {
    "YAY!!",
    "OMG!!",
    "LET'S GO",
    "🎉",
    "WOOO!",
    "MUTATE!!",
    "YES!!",
}

local WALK: EmotionSet = {
    "hmm…",
    "next?",
    "👀",
    "curious",
    "this way",
    "ooh",
}

local EVOLVE: EmotionSet = {
    "EVOLVED!!",
    "RARE!!",
    "UNREAL!!",
    "HOLY!!",
    "NO WAY!!",
    "LEGEND!!",
    "🔥🔥🔥",
}

local NpcEmotionDatabase = {}

function NpcEmotionDatabase.list(rarity: string): EmotionSet
    return BY_RARITY[rarity] or BY_RARITY.common
end

function NpcEmotionDatabase.celebrateList(): EmotionSet
    return CELEBRATE
end

-- rng01 in [0,1)
function NpcEmotionDatabase.pick(rarity: string, rng01: number): string
    local list = NpcEmotionDatabase.list(rarity)
    if #list == 0 then
        return "…"
    end
    local t = math.clamp(rng01, 0, 0.999999)
    local idx = math.floor(t * #list) + 1
    return list[idx]
end

function NpcEmotionDatabase.pickCelebrate(rng01: number): string
    local list = CELEBRATE
    local t = math.clamp(rng01, 0, 0.999999)
    local idx = math.floor(t * #list) + 1
    return list[idx]
end

function NpcEmotionDatabase.pickWalk(rng01: number): string
    local list = WALK
    local t = math.clamp(rng01, 0, 0.999999)
    local idx = math.floor(t * #list) + 1
    return list[idx]
end

function NpcEmotionDatabase.pickEvolve(rng01: number): string
    local list = EVOLVE
    local t = math.clamp(rng01, 0, 0.999999)
    local idx = math.floor(t * #list) + 1
    return list[idx]
end

return NpcEmotionDatabase
