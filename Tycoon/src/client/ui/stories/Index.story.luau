--!strict
-- Hoarcekat: Index modal (force-open, scrim + DesignRoot). Path: ReplicatedStorage.UI.stories.Index
-- No ModalHost portal (stays in Hoarcekat target). Sounds via playUiSound (no client.core require).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local HudProvider = require(script.Parent.Parent.context.HudProvider)
local IndexPanel = require(script.Parent.Parent.components.IndexPanel)
local ModalScrim = require(script.Parent.Parent.components.ModalScrim)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local adapt = require(script.Parent.Parent.adapt)
local mount = require(script.Parent.mount)

local MOCK_HUD: NetTypes.HudSyncPayload = {
    coins = 1000,
    pendingCash = 0,
    backpackEggs = 0,
    luckyBlocks = 0,
    shopQueue = 0,
    processPerSec = 1,
    multiplier = 1,
    unitCount = 1,
    emptySlots = 5,
    nextUnitCost = 1,
    rebirths = 0,
    autoCollectEggs = false,
    autoCollectCash = false,
    doubleItems = false,
    indexMaxTier = 4,
    productionLevel = 0,
    buyCount = 0,
    exclusiveOfferEndsAt = 0,
    exclusiveHeartOwned = false,
    exclusiveRebirthOwned = false,
}

local function IndexModal(): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, {
        Scrim = React.createElement(ModalScrim, {
            onActivated = function()
                print("[Index story] scrim")
            end,
        }),
        Root = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            Design = React.createElement(DesignRoot, {
                config = adapt.DEFAULT,
            }, {
                Panel = React.createElement(IndexPanel, {
                    onClose = function()
                        print("[Index story] close")
                    end,
                }),
            }),
        }),
    })
end

local function StoryApp(): React.Node
    return React.createElement(HudProvider, {
        hud = MOCK_HUD,
        buyUpgrade = function(_upgradeId: string) end,
        indexOpen = true,
        setIndexOpen = function(_open: boolean) end,
    }, {
        Modal = React.createElement(IndexModal),
    })
end

return mount.screen(React.createElement(StoryApp))
