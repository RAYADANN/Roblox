--!strict
-- Player profile for Showroom.

local ExhibitTypes
if script and script.Parent then
    ExhibitTypes = require(script.Parent.Exhibit)
else
    ExhibitTypes = require("./Exhibit")
end

local Constants
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
else
    Constants = require("../data/Constants")
end

export type ExhibitInstance = ExhibitTypes.ExhibitInstance
export type DispenserOffer = ExhibitTypes.DispenserOffer

-- Grown exhibit held off the income stand during / after auction.
export type AuctionHold = {
    exhibit: ExhibitInstance,
    runsCompleted: number, -- 0..MAX; increments when a run finishes
    phase: "running" | "finished" | "sold",
    lastMaxBid: number,
    originSlot: number,
    fromFavorite: boolean?, -- true → auction runs on FavoritePlace pad
    bidderCount: number?,
    lastBidsJson: string?, -- full bid list after a run finishes
}

export type PlayerData = {
    coins: number,
    plotId: number?,
    rebirths: number, -- auction value multiplier; full rebirth loop later
    slots: { ExhibitInstance? },
    favoriteSlots: { ExhibitInstance? }, -- passive income stands (FavoritePlace)
    favoriteBank: number, -- uncollected coins on FavoritePlace
    inventory: { ExhibitInstance },
    handUid: string?, -- equipped inventory item (must exist in inventory)
    offers: { DispenserOffer },
    offersGeneratedAt: number,
    firstSessionComplete: boolean,
    auctionHold: AuctionHold?,
}

local function emptySlots(): { ExhibitInstance? }
    local slots: { ExhibitInstance? } = table.create(Constants.SLOT_COUNT)
    for i = 1, Constants.SLOT_COUNT do
        slots[i] = nil
    end
    return slots
end

local function emptyFavoriteSlots(): { ExhibitInstance? }
    local slots: { ExhibitInstance? } = table.create(Constants.FAVORITE_SLOT_COUNT)
    for i = 1, Constants.FAVORITE_SLOT_COUNT do
        slots[i] = nil
    end
    return slots
end

local TEMPLATE: PlayerData = {
    coins = Constants.START_COINS,
    plotId = nil,
    rebirths = 0,
    slots = emptySlots(),
    favoriteSlots = emptyFavoriteSlots(),
    favoriteBank = 0,
    inventory = {},
    handUid = nil,
    offers = {},
    offersGeneratedAt = 0,
    firstSessionComplete = false,
    auctionHold = nil,
}

return {
    TEMPLATE = TEMPLATE,
    emptySlots = emptySlots,
    emptyFavoriteSlots = emptyFavoriteSlots,
}
