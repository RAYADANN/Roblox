--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type HudContextValue = {
    hud: NetTypes.HudSyncPayload,
    buyUpgrade: (upgradeId: string) -> (),
    onBoostOffer: ((offerId: string) -> ())?,
    onBoostOfferSeen: (() -> ())?,
}

local defaultValue: HudContextValue = {
    hud = {
        coins = 0,
        rebirths = 0,
        upgrades = {},
        handUid = "",
        offersJson = "[]",
        slotsJson = "[]",
        inventoryJson = "[]",
        sellBoxCoins = 0,
        sellBoxDeposits = 0,
        sellCratesJson = "[]",
        indexFoundJson = "[]",
        rewardTrackStartedAt = 0,
        rewardClaimedJson = "[]",
        tutorialCompleted = false,
        boostOfferEndsAt = 0,
        ownsLuckyX2 = false,
        ownsLuckyX4 = false,
        ownsMoneyX2 = false,
        pendingOfflineCoins = 0,
    },
    buyUpgrade = function() end,
    onBoostOffer = function(_offerId: string) end,
    onBoostOfferSeen = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
