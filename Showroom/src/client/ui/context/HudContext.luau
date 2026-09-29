--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type HudContextValue = {
    hud: NetTypes.HudSyncPayload,
    pickOffer: (offerUid: string) -> (),
    placeSlot: (slotIndex: number) -> (),
    removeSlot: (slotIndex: number) -> (),
    sellSlot: (slotIndex: number) -> (),
    refreshOffers: () -> (),
    selectHand: (itemUid: string) -> (),
}

local emptyHud: NetTypes.HudSyncPayload = {
    coins = 0,
    plotId = 0,
    favoriteBank = 0,
    offers = {},
    slots = {},
    inventory = {},
    handUid = nil,
    handName = nil,
}

local defaultValue: HudContextValue = {
    hud = emptyHud,
    pickOffer = function() end,
    placeSlot = function() end,
    removeSlot = function() end,
    sellSlot = function() end,
    refreshOffers = function() end,
    selectHand = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
