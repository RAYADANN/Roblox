--!strict
-- Root: HUD state + Zap + PlotPromptBinder + post-auction decision overlay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local AuctionPanel = require(script.Parent.panels.AuctionPanel)
local HudContext = require(script.Parent.context.HudContext)
local HudProvider = require(script.Parent.context.HudProvider)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local Notification = require(script.Parent.Parent.core.Notification)
local PlotPromptBinder = require(script.Parent.Parent.core.PlotPromptBinder)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local Zap = require(script.Parent.Parent.net.NetClient)

local EMPTY: NetTypes.HudSyncPayload = {
    coins = 0,
    plotId = 0,
    favoriteBank = 0,
    offers = {},
    slots = {},
    inventory = {},
    handUid = nil,
    handName = nil,
}

local EMPTY_AUCTION: AuctionPanel.AuctionView = {
    phase = "none",
    displayName = "",
    rarity = "",
    sizeLabel = "",
    mutationLabel = "",
    mutationCount = 0,
    currentBid = 0,
    maxBid = 0,
    remainingSec = 0,
    runsUsed = 0,
    maxRuns = 3,
    nextCommission = 0,
    lastBuyer = "",
    bidsJson = "[]",
    colorR = 100,
    colorG = 100,
    colorB = 100,
    scale = 1,
}

local function GameRoot(): React.Node
    local hud, setHud = React.useState(EMPTY)
    local auction, setAuction = React.useState(EMPTY_AUCTION)

    React.useEffect(function()
        local cleanups = {
            Zap.PlayerDataSync.On(function(value)
                local nextHud = NetTypes.fromZapSync(value)
                setHud(nextHud)
                PlotPromptBinder.setHud(nextHud)
            end),
            Zap.AuctionSync.On(function(value)
                setAuction({
                    phase = value.phase,
                    displayName = value.displayName,
                    rarity = value.rarity,
                    sizeLabel = value.sizeLabel,
                    mutationLabel = value.mutationLabel,
                    mutationCount = value.mutationCount,
                    currentBid = value.currentBid,
                    maxBid = value.maxBid,
                    remainingSec = value.remainingSec,
                    runsUsed = value.runsUsed,
                    maxRuns = value.maxRuns,
                    nextCommission = value.nextCommission,
                    lastBuyer = value.lastBuyer,
                    bidsJson = value.bidsJson,
                    colorR = value.colorR,
                    colorG = value.colorG,
                    colorB = value.colorB,
                    scale = value.scale,
                })
            end),
            Zap.Notify.On(function(payload)
                if payload.kind == "sold" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `Sold for {payload.payload}`,
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "react" then
                    Notification.show({
                        text = `{payload.payload} reacted!`,
                        color = Color3.fromRGB(120, 180, 255),
                    })
                elseif payload.kind == "picked" then
                    SoundManager.play("ui_click")
                elseif payload.kind == "evolved" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `{payload.payload} evolved!`,
                        color = Color3.fromRGB(255, 200, 60),
                    })
                elseif payload.kind == "mutated" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `Mutation: {payload.payload}`,
                        color = Color3.fromRGB(255, 120, 220),
                    })
                elseif payload.kind == "placed" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = "Placed on stand",
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "favorite" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = payload.payload,
                        color = Color3.fromRGB(255, 180, 90),
                    })
                elseif payload.kind == "collect" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = `Collected {payload.payload}`,
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "collect_fail" or payload.kind == "place_fail" then
                    SoundManager.play("sell_fail")
                    Notification.show({
                        text = payload.payload,
                        color = Color3.fromRGB(255, 120, 80),
                    })
                elseif payload.kind == "auction_start" then
                    SoundManager.play("ui_confirm")
                    Notification.show({
                        text = "Auction started!",
                        color = Color3.fromRGB(255, 212, 38),
                    })
                elseif payload.kind == "auction_done" then
                    SoundManager.play("ui_confirm")
                elseif payload.kind == "auction_fee" then
                    Notification.show({
                        text = `Auction fee: {payload.payload}`,
                        color = Color3.fromRGB(255, 180, 80),
                    })
                end
            end),
        }
        return function()
            for _, cleanup in cleanups do
                cleanup()
            end
        end
    end, {})

    local noop = React.useCallback(function() end, {})

    local selectHand = React.useCallback(function(itemUid: string)
        SoundManager.play("ui_click")
        local result = Zap.SelectHand.Call(itemUid)
        if not result.success then
            Notification.show({
                text = result.error or "Cannot select",
                color = Color3.fromRGB(255, 120, 80),
            })
        end
    end, {})

    local onAuctionSell = React.useCallback(function()
        SoundManager.play("ui_click")
        local result = Zap.ConfirmAuctionSell.Call()
        if not result.success then
            SoundManager.play("sell_fail")
            Notification.show({
                text = result.error or "Cannot sell",
                color = Color3.fromRGB(255, 120, 80),
            })
        end
    end, {})

    local onAuctionRerun = React.useCallback(function()
        SoundManager.play("ui_click")
        local result = Zap.RerunAuction.Call()
        if not result.success then
            SoundManager.play("sell_fail")
            local msg = result.error or "Cannot rerun"
            if result.error == "need_coins" then
                msg = "Not enough coins for fee"
            elseif result.error == "max_auctions" then
                msg = "Max auctions reached"
            end
            Notification.show({
                text = msg,
                color = Color3.fromRGB(255, 120, 80),
            })
        end
    end, {})

    local value: HudContext.HudContextValue = React.useMemo(function()
        return {
            hud = hud,
            pickOffer = noop :: any,
            placeSlot = noop :: any,
            removeSlot = noop :: any,
            sellSlot = noop :: any,
            refreshOffers = noop :: any,
            selectHand = selectHand,
        }
    end, { hud, noop, selectHand } :: { any })

    return React.createElement(HudProvider, {
        value = value,
    }, {
        App = React.createElement(App),
        Auction = if auction.phase == "finished"
            then React.createElement(AuctionPanel, {
                auction = auction,
                onSell = onAuctionSell,
                onRerun = onAuctionRerun,
            })
            else nil,
    })
end

return GameRoot
