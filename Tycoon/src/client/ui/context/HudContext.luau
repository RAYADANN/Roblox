--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local EMPTY_HUD: NetTypes.HudSyncPayload = {
    coins = 0,
    pendingCash = 0,
    backpackEggs = 0,
    luckyBlocks = 0,
    shopQueue = 0,
    processPerSec = 2,
    multiplier = 1,
    unitCount = 0,
    emptySlots = 40,
    nextUnitCost = 1,
    rebirths = 0,
    autoCollectEggs = false,
    autoCollectCash = false,
    doubleItems = false,
    indexMaxTier = 0,
    productionLevel = 0,
    buyCount = 0,
    exclusiveOfferEndsAt = 0,
    exclusiveHeartOwned = false,
    exclusiveRebirthOwned = false,
}

export type HudContextValue = {
    hud: NetTypes.HudSyncPayload,
    buyUpgrade: (upgradeId: string) -> (),
    -- Demo cash-offer pills; GameRoot prompts the matching DevProduct.
    onMoneyOffer: (productId: number) -> (),
    -- Exclusive spin offers (pink platform, …).
    onExclusiveOffer: (offerId: string) -> (),
    rebirthOpen: boolean,
    setRebirthOpen: (open: boolean) -> (),
    indexOpen: boolean,
    setIndexOpen: (open: boolean) -> (),
    requestRebirth: () -> (),
    onSkipRebirth: () -> (),
    -- Playtest: open FTUE overlay from HUD.
    tutorialOpen: boolean,
    tutorialStep: number,
    startTutorial: () -> (),
    advanceTutorial: () -> (),
    skipTutorial: () -> (),
}

local defaultValue: HudContextValue = {
    hud = EMPTY_HUD,
    buyUpgrade = function() end,
    onMoneyOffer = function(_productId: number) end,
    onExclusiveOffer = function(_offerId: string) end,
    rebirthOpen = false,
    setRebirthOpen = function(_open: boolean) end,
    indexOpen = false,
    setIndexOpen = function(_open: boolean) end,
    requestRebirth = function() end,
    onSkipRebirth = function() end,
    tutorialOpen = false,
    tutorialStep = 1,
    startTutorial = function() end,
    advanceTutorial = function() end,
    skipTutorial = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
