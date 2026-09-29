--!strict
-- Player profile for AnimeTycoon.

local ContainerTypes
local Constants
if script and script.Parent then
    ContainerTypes = require(script.Parent.Container)
    Constants = require(script.Parent.Parent.data.Constants)
else
    ContainerTypes = require("./Container")
    Constants = require("../data/Constants")
end

export type ContainerInstance = ContainerTypes.ContainerInstance
export type StandOffer = ContainerTypes.StandOffer
export type UpgradeLevels = { [string]: number }

export type PlayerData = {
    coins: number,
    rebirths: number,
    upgrades: UpgradeLevels,
    slots: { ContainerInstance? },
    inventory: { ContainerInstance },
    handUid: string?,
    offers: { StandOffer },
    offersGeneratedAt: number,
    firstSessionComplete: boolean,
}

local function emptySlots(): { ContainerInstance? }
    local slots: { ContainerInstance? } = table.create(Constants.SLOT_COUNT)
    for i = 1, Constants.SLOT_COUNT do
        slots[i] = nil
    end
    return slots
end

local TEMPLATE: PlayerData = {
    coins = Constants.START_COINS,
    rebirths = 0,
    upgrades = {},
    slots = emptySlots(),
    inventory = {},
    handUid = nil,
    offers = {},
    offersGeneratedAt = 0,
    firstSessionComplete = false,
}

return {
    TEMPLATE = TEMPLATE,
    emptySlots = emptySlots,
}
