--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.HudContext)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

export type Props = {
    children: React.Node,
    hud: NetTypes.HudSyncPayload,
    match: NetTypes.MatchSyncPayload?,
    skinOffer: HudContext.SkinOffer?,
    health: number,
    maxHealth: number,
    toasts: { HudContext.ToastItem },
    pushToast: HudContext.PushToast,
    requestRematch: () -> (),
    equipOfferedSkin: () -> (),
    equipSkin: (skinId: string) -> (),
    startBotMatch: () -> (),
    setLookSensitivity: (value: number) -> (),
    settingsOpen: boolean,
    setSettingsOpen: (open: boolean) -> (),
    inventoryOpen: boolean,
    setInventoryOpen: (open: boolean) -> (),
    inventoryTab: HudContext.InventoryTab,
    setInventoryTab: (tab: HudContext.InventoryTab) -> (),
    shopOpen: boolean,
    setShopOpen: (open: boolean) -> (),
}

local function HudProvider(props: Props): React.Node
    local value = React.useMemo(function()
        return {
            hud = props.hud,
            match = props.match,
            skinOffer = props.skinOffer,
            health = props.health,
            maxHealth = props.maxHealth,
            toasts = props.toasts,
            pushToast = props.pushToast,
            requestRematch = props.requestRematch,
            equipOfferedSkin = props.equipOfferedSkin,
            equipSkin = props.equipSkin,
            startBotMatch = props.startBotMatch,
            setLookSensitivity = props.setLookSensitivity,
            settingsOpen = props.settingsOpen,
            setSettingsOpen = props.setSettingsOpen,
            inventoryOpen = props.inventoryOpen,
            setInventoryOpen = props.setInventoryOpen,
            inventoryTab = props.inventoryTab,
            setInventoryTab = props.setInventoryTab,
            shopOpen = props.shopOpen,
            setShopOpen = props.setShopOpen,
        }
    end, {
        props.hud,
        props.match,
        props.skinOffer,
        props.health,
        props.maxHealth,
        props.toasts,
        props.pushToast,
        props.requestRematch,
        props.equipOfferedSkin,
        props.equipSkin,
        props.startBotMatch,
        props.setLookSensitivity,
        props.settingsOpen,
        props.setSettingsOpen,
        props.inventoryOpen,
        props.setInventoryOpen,
        props.inventoryTab,
        props.setInventoryTab,
        props.shopOpen,
        props.setShopOpen,
    })

    return React.createElement(HudContext.Provider, { value = value }, props.children)
end

return HudProvider
