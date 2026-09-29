--!strict
-- Container instance types (profile + world publish). Pure.

local RarityDatabase
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
else
    RarityDatabase = require("../data/RarityDatabase")
end

export type RarityId = RarityDatabase.RarityId

export type ContainerInstance = {
    uid: string,
    templateId: string,
    boxModelName: string,
    rarity: RarityId,
    heroId: string,
    displayName: string,
    baseIncome: number,
    mutations: { string },
    placedAt: number?, -- unix sec when placed; nil in inventory
    slotIndex: number?, -- 1..10 when on Ramp
    unpackProgress: number, -- 0..1
    unpacked: boolean,
    incomeRate: number, -- payout per mini (display)
}

export type StandOffer = {
    uid: string,
    templateId: string,
    boxModelName: string,
    rarity: RarityId,
    heroId: string,
    displayName: string,
    baseIncome: number,
    mutations: { string },
}

return {}
