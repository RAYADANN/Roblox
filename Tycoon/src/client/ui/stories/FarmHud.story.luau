--!strict
-- Hoarcekat: full Farm HUD (rail + coins + bag). Path: ReplicatedStorage.UI.stories.FarmHud
-- Screen Scale like StarterGui.HUD (no DesignRoot letterbox).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FarmHud = require(script.Parent.Parent.components.FarmHud)
local HudProvider = require(script.Parent.Parent.context.HudProvider)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local mount = require(script.Parent.mount)

local MOCK_HUD: NetTypes.HudSyncPayload = {
    coins = 1000,
    pendingCash = 25,
    backpackEggs = 12,
    luckyBlocks = 0,
    shopQueue = 40,
    processPerSec = 2,
    multiplier = 1.2,
    unitCount = 2,
    emptySlots = 4,
    nextUnitCost = 1,
    rebirths = 0,
    autoCollectEggs = false,
    autoCollectCash = false,
    doubleItems = false,
    indexMaxTier = 0,
    productionLevel = 0,
    buyCount = 45,
    exclusiveOfferEndsAt = 0,
    exclusiveHeartOwned = false,
    exclusiveRebirthOwned = false,
}

local function StoryApp(): React.Node
    return React.createElement(HudProvider, {
        hud = MOCK_HUD,
        buyUpgrade = function(_upgradeId: string) end,
    }, {
        Hud = React.createElement(FarmHud),
    })
end

return mount.screen(React.createElement(StoryApp))
