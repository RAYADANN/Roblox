--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local Toast = require(script.Parent.Parent.components.Toast)

export type ToastItem = Toast.ToastItem

export type PushToast = (opts: { text: string, color: Color3?, duration: number? }) -> ()

export type SkinOffer = {
    token: number,
    skinId: string,
    owned: boolean,
}

export type InventoryTab = "gun" | "case"

export type HudContextValue = {
    hud: NetTypes.HudSyncPayload,
    match: NetTypes.MatchSyncPayload?,
    skinOffer: SkinOffer?,
    health: number,
    maxHealth: number,
    toasts: { ToastItem },
    pushToast: PushToast,
    requestRematch: () -> (),
    equipOfferedSkin: () -> (),
    equipSkin: (skinId: string) -> (),
    startBotMatch: () -> (),
    setLookSensitivity: (value: number) -> (),
    settingsOpen: boolean,
    setSettingsOpen: (open: boolean) -> (),
    inventoryOpen: boolean,
    setInventoryOpen: (open: boolean) -> (),
    inventoryTab: InventoryTab,
    setInventoryTab: (tab: InventoryTab) -> (),
    shopOpen: boolean,
    setShopOpen: (open: boolean) -> (),
}

local defaultValue: HudContextValue = {
    hud = {
        wins = 0,
        losses = 0,
        equippedSkinId = "usp_default",
        lookSensitivity = 1,
        crosshairId = "classic",
        ownedSkinIds = { "usp_default" },
    },
    match = nil,
    skinOffer = nil,
    health = 100,
    maxHealth = 100,
    toasts = {},
    pushToast = function() end,
    requestRematch = function() end,
    equipOfferedSkin = function() end,
    equipSkin = function() end,
    startBotMatch = function() end,
    setLookSensitivity = function() end,
    settingsOpen = false,
    setSettingsOpen = function() end,
    inventoryOpen = false,
    setInventoryOpen = function() end,
    inventoryTab = "gun",
    setInventoryTab = function() end,
    shopOpen = false,
    setShopOpen = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
