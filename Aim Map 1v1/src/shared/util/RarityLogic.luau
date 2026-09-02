--!strict
-- CS-style rarity → SimPop block tone (inventory / shop / cases).

export type RarityId = "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic"
export type BlockTone = "blue" | "green" | "purple" | "orange" | "red"

local ORDER: { RarityId } = {
    "common",
    "uncommon",
    "rare",
    "epic",
    "legendary",
    "mythic",
}

-- Consumer/blue → mil-spec green → restricted purple → classified orange → covert red → gold/mythic red
local TONE_BY_RARITY: { [string]: BlockTone } = {
    common = "blue",
    uncommon = "green",
    rare = "purple",
    epic = "orange",
    legendary = "orange",
    mythic = "red",
}

local RarityLogic = {}

function RarityLogic.isValid(id: string): boolean
    return TONE_BY_RARITY[id] ~= nil
end

function RarityLogic.blockTone(rarity: string): BlockTone
    return TONE_BY_RARITY[rarity] or "blue"
end

function RarityLogic.order(): { RarityId }
    return ORDER
end

return RarityLogic
