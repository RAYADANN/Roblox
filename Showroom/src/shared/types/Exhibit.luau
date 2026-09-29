--!strict
-- Exhibit instance types (profile + world publish). Pure.

local RarityDatabase
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
else
    RarityDatabase = require("../data/RarityDatabase")
end

export type RarityId = RarityDatabase.RarityId

export type SizeId = "small" | "medium" | "large" | "giant"

export type ExhibitInstance = {
    uid: string,
    templateId: string,
    rarity: RarityId,
    sizeId: SizeId,
    styleId: string,
    characterId: string,
    displayName: string,
    baseIncome: number,
    attention: number,
    placedAt: number?, -- unix sec when placed; nil if in hand/inventory
    slotIndex: number?, -- 1..6 when placed
    evolveProgress: number, -- 0..1 persisted snapshot
    evolved: boolean,
    mutated: boolean,
    mutations: { string }, -- mutation ids; label = Name-Name-Name
    mutationStacks: number, -- #mutations (persisted mirror)
    npcBase: number, -- rolled crowd size; 0 if shunned
    npcShunned: boolean, -- NPCs refused to approach
    celebrateUntil: number, -- unix sec; NPCs jump / rush while now < this
    celebrateKind: string, -- "" | "mutate" | "evolve"
    animId: string, -- spin | bounce | tumble | sway | pulse
    incomeRate: number,
}

export type DispenserOffer = {
    uid: string,
    templateId: string,
    rarity: RarityId,
    sizeId: SizeId,
    styleId: string,
    characterId: string,
    displayName: string,
    baseIncome: number,
    mutations: { string }, -- egg may start with growth mutations
}

export type SlotState = {
    exhibit: ExhibitInstance?,
}

return {}
