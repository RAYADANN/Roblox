--!strict
-- Hoarcekat: Rebirth modal (force-open, scrim + DesignRoot). Path: ReplicatedStorage.UI.stories.Rebirth
-- No ModalHost portal (stays in Hoarcekat target). No client.core / ReplicatedStorage.core.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local HudContext = require(script.Parent.Parent.context.HudContext)
local HudProvider = require(script.Parent.Parent.context.HudProvider)
local ModalScrim = require(script.Parent.Parent.components.ModalScrim)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local RebirthLogic = require(ReplicatedStorage.shared.util.RebirthLogic)
local RebirthPanel = require(script.Parent.Parent.components.RebirthPanel)
local adapt = require(script.Parent.Parent.adapt)
local mount = require(script.Parent.mount)

local REBIRTHS = 0

local function baseHud(coins: number, rebirths: number): NetTypes.HudSyncPayload
    return {
        coins = coins,
        pendingCash = 0,
        backpackEggs = 0,
        luckyBlocks = 0,
        shopQueue = 0,
        processPerSec = 1,
        multiplier = RebirthLogic.valueMultiplier(rebirths),
        unitCount = 1,
        emptySlots = 5,
        nextUnitCost = 1,
        rebirths = rebirths,
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
end

local function RebirthModal(): React.Node
    local ctx = React.useContext(HudContext)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, {
        Scrim = React.createElement(ModalScrim, {
            onActivated = function()
                print("[Rebirth story] scrim")
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
                Panel = React.createElement(RebirthPanel, {
                    coins = ctx.hud.coins,
                    rebirths = ctx.hud.rebirths,
                    onClose = function()
                        print("[Rebirth story] close")
                    end,
                    onRebirth = function()
                        ctx.requestRebirth()
                    end,
                    onSkip = function()
                        ctx.onSkipRebirth()
                    end,
                }),
            }),
        }),
    })
end

local function StoryApp(): React.Node
    local canAfford, setCanAfford = React.useState(true)
    local need = RebirthLogic.cost(REBIRTHS)
    local coins = if canAfford then need else math.floor(need * 0.25)
    local hud = baseHud(coins, REBIRTHS)

    return React.createElement(HudProvider, {
        hud = hud,
        buyUpgrade = function(_upgradeId: string) end,
        rebirthOpen = true,
        setRebirthOpen = function(_open: boolean) end,
        requestRebirth = function()
            print("[Rebirth story] requestRebirth")
        end,
        onSkipRebirth = function()
            print("[Rebirth story] onSkipRebirth")
        end,
    }, {
        Modal = React.createElement(RebirthModal),
        Toggle = React.createElement("TextButton", {
            Size = UDim2.fromOffset(160, 36),
            Position = UDim2.new(0, 12, 1, -12),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Color3.fromRGB(40, 44, 48),
            BorderSizePixel = 0,
            Text = if canAfford then "State: ready" else "State: not ready",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            ZIndex = 50,
            [React.Event.Activated] = function()
                setCanAfford(not canAfford)
            end,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
        }),
    })
end

return mount.screen(React.createElement(StoryApp))
