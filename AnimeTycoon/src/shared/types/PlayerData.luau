--!strict
-- Player profile for AnimeTycoon.

local ContainerTypes
local Constants
local SlotMap
if script and script.Parent then
    ContainerTypes = require(script.Parent.Container)
    Constants = require(script.Parent.Parent.data.Constants)
    SlotMap = require(script.Parent.Parent.util.SlotMap)
else
    ContainerTypes = require("./Container")
    Constants = require("../data/Constants")
    SlotMap = require("../util/SlotMap")
end

export type ContainerInstance = ContainerTypes.ContainerInstance
export type StandOffer = ContainerTypes.StandOffer
export type UpgradeLevels = { [string]: number }
--- String-keyed map ("1".."30") — DataStore-safe (no sparse numeric arrays).
export type SlotTable = { [string]: ContainerInstance }

export type ActiveSellBox = {
    coins: number,
    depositCount: number,
}

export type SellCrate = {
    uid: string,
    coins: number,
    depositCount: number,
}

export type PlayerData = {
    coins: number,
    rebirths: number,
    upgrades: UpgradeLevels,
    slots: SlotTable,
    inventory: { ContainerInstance },
    handUid: string?,
    offers: { StandOffer },
    offersGeneratedAt: number,
    firstSessionComplete: boolean,
    --- FTUE finished (or skipped). Client drives steps; server stores completion.
    tutorialCompleted: boolean,
    --- False until the first stand buy (that container unpacks in 3s).
    firstContainerBought: boolean,
    --- Pad SellBox (not yet taken). Coins leave pocket until SellGuy.
    activeSellBox: ActiveSellBox,
    --- Taken SellBoxes waiting to sell at SellGuy.
    sellCrates: { SellCrate },
    --- Index discovery keys: heroId or heroId:mutationId (see IndexLogic.findKey).
    indexFound: { string },
    --- First HUD view of right-rail boost offers (unix). 0 = not started.
    boostOfferSeenAt: number,
    ownsLuckyX2: boolean,
    ownsLuckyX4: boolean,
    ownsMoneyX2: boolean,
    --- Unix when player last left / settled (offline accrual).
    lastSeenAt: number,
    --- Coins waiting to claim via Offline Earnings window.
    pendingOfflineCoins: number,
}

local function emptySlots(): SlotTable
    return SlotMap.empty()
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
    tutorialCompleted = false,
    firstContainerBought = false,
    activeSellBox = { coins = 0, depositCount = 0 },
    sellCrates = {},
    indexFound = {},
    boostOfferSeenAt = 0,
    ownsLuckyX2 = false,
    ownsLuckyX4 = false,
    ownsMoneyX2 = false,
    lastSeenAt = 0,
    pendingOfflineCoins = 0,
}

return {
    TEMPLATE = TEMPLATE,
    emptySlots = emptySlots,
}
