--!strict
-- HUD + окна: Shop / Index / Rewards. Blur + zoom через useModalFocus.
-- Слои (Sibling): icons < windows(50) < FX(60) < money(100).
-- SoundManager опционален: в Hoarcekat UI живёт в ReplicatedStorage без client.core.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BoostOfferLogic = require(ReplicatedStorage.shared.util.BoostOfferLogic)
local BoostOffers = require(script.Parent.hud.components.BoostOffers)
local ExclusiveShopPanel = require(script.Parent.shop.ExclusiveShopPanel)
local Formatters = require(script.Parent.util.Formatters)
local FxOverlay = require(script.Parent.fx.FxOverlay)
local HudContext = require(script.Parent.context.HudContext)
local HudGate = require(script.Parent.util.HudGate)
local HudPanel = require(script.Parent.hud.HudPanel)
local IndexMockData = require(script.Parent.index.MockData)
local IndexPanel = require(script.Parent.index.IndexPanel)
local MoneyDisplay = require(script.Parent.hud.components.MoneyDisplay)
local MoneyGainFx = require(script.Parent.fx.MoneyGainFx)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local OfflineEarningsPanel = require(script.Parent.offlineEarnings.OfflineEarningsPanel)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)
local RewardTimerLogic = require(ReplicatedStorage.shared.util.RewardTimerLogic)
local RewardsMockData = require(script.Parent.rewards.MockData)
local RewardsPanel = require(script.Parent.rewards.RewardsPanel)
local ShopMockData = require(script.Parent.shop.MockData)
local UpgradesPanel = require(script.Parent.upgrades.UpgradesPanel)
local useModalFocus = require(script.Parent.hooks.useModalFocus)

-- Zap only exists under StarterPlayer (not in Hoarcekat ReplicatedStorage.UI).
local function getZap(): any?
    local parent = script.Parent.Parent
    local net = parent:FindFirstChild("net")
    if net == nil then
        return nil
    end
    local mod = net:FindFirstChild("NetClient")
    if mod == nil then
        return nil
    end
    local ok, zap = pcall(require, mod)
    if ok then
        return zap
    end
    return nil
end

export type WindowId = "shop" | "index" | "rewards" | "upgrades"

export type Props = {
    coins: number?,
    indexFoundJson: string?,
    rewardTrackStartedAt: number?,
    rewardClaimedJson: string?,
    pendingOfflineCoins: number?,
    --- Server claim; returns coinsGranted (0 for case / fail).
    onClaimReward: ((rewardId: string) -> number)?,
    onClaimOffline: (() -> ())?,
    onDoubleOffline: (() -> ())?,
    onRebirth: (() -> ())?,
    onUpgrades: (() -> ())?,
}

local function playClick()
    local core = script.Parent.Parent:FindFirstChild("core")
    if core == nil then
        return
    end
    local module = core:FindFirstChild("SoundManager")
    if module == nil then
        return
    end
    local ok, sound = pcall(require, module)
    if ok and sound ~= nil then
        sound.play("ui_click")
    end
end

local function nowSec(): number
    return math.floor(workspace:GetServerTimeNow())
end

local function parseClaimedIds(raw: string?): { string }
    local decoded = NetTypes.decodeJsonArray(raw or "[]")
    local ids: { string } = {}
    for _, id in decoded do
        if typeof(id) == "string" then
            table.insert(ids, id)
        end
    end
    return ids
end

local function buildRewardItems(startedAt: number?, claimedJson: string?)
    local opts: RewardsMockData.ItemsOpts = {
        claimedIds = parseClaimedIds(claimedJson),
    }
    if startedAt ~= nil and startedAt > 0 then
        opts.trackStartedAt = startedAt
    end
    return RewardsMockData.items(opts)
end

local function HudShell(props: Props): React.Node
    local ctx = React.useContext(HudContext)
    local open, setOpen = React.useState(nil :: WindowId?)
    local coins, setCoins = React.useState(props.coins or 100_000_000)
    local hudVisible, setHudVisible = React.useState(HudGate.isVisible())
    local offlineDismissed, setOfflineDismissed = React.useState(false)
    local rewardItems, setRewardItems = React.useState(function()
        return buildRewardItems(props.rewardTrackStartedAt, props.rewardClaimedJson)
    end)
    local now, setNow = React.useState(nowSec)
    local pendingOffline = math.max(0, props.pendingOfflineCoins or 0)
    local showOffline = pendingOffline > 0 and not offlineDismissed and hudVisible
    useModalFocus((open ~= nil or showOffline) and hudVisible)

    React.useEffect(function()
        return HudGate.onChanged(function(visible)
            setHudVisible(visible)
            if not visible then
                setOpen(nil)
            end
        end)
    end, {})

    React.useEffect(function()
        if props.coins ~= nil then
            setCoins(props.coins)
        end
    end, { props.coins })

    React.useEffect(function()
        if (props.pendingOfflineCoins or 0) > 0 then
            setOfflineDismissed(false)
        end
    end, { props.pendingOfflineCoins })

    React.useEffect(function()
        setRewardItems(buildRewardItems(props.rewardTrackStartedAt, props.rewardClaimedJson))
    end, { props.rewardTrackStartedAt, props.rewardClaimedJson } :: { unknown })

    React.useEffect(function()
        return function()
            FxOverlay.setHost(nil)
        end
    end, {})

    React.useEffect(function()
        local acc = 0
        local conn = RunService.Heartbeat:Connect(function(dt)
            acc += dt
            if acc < 0.5 then
                return
            end
            acc = 0
            setNow(nowSec())
        end)
        return function()
            conn:Disconnect()
        end
    end, {})

    local claimRows = {}
    for _, item in rewardItems do
        table.insert(claimRows, {
            claimed = item.claimed == true,
            unlockAt = item.unlockAt,
        })
    end
    local claimableIndex = RewardTimerLogic.firstClaimableIndex(claimRows, now)
    local giftAttention = claimableIndex ~= nil and open ~= "rewards"

    local function close()
        playClick()
        setOpen(nil)
    end

    local function openWindow(id: WindowId)
        playClick()
        setOpen(id)
    end

    local function handleRewardClaim(id: string, from: Vector2)
        local slotCoins = 0
        for _, item in rewardItems do
            if item.id == id then
                slotCoins = item.coins or 0
                break
            end
        end

        local gain = slotCoins
        local serverDriven = props.onClaimReward ~= nil
        if serverDriven then
            gain = props.onClaimReward(id)
            if gain < 0 then
                return
            end
        end

        setRewardItems(function(prev)
            local nextItems = table.clone(prev)
            for i, item in nextItems do
                if item.id == id then
                    local copy = table.clone(item)
                    copy.claimed = true
                    nextItems[i] = copy
                    break
                end
            end
            return nextItems
        end)

        if gain <= 0 then
            return
        end

        MoneyGainFx.play({
            from = from,
            amount = gain,
            onLanded = if serverDriven
                then nil
                else function()
                    setCoins(function(c)
                        return c + gain
                    end)
                end,
        })
    end

    local overlay: React.Node? = nil
    if open == "shop" then
        local hud = ctx.hud
        local endsAt = hud.boostOfferEndsAt or 0
        local seenAt = if endsAt > 0 then endsAt - BoostOfferLogic.durationSec() else 0
        local saleActive = BoostOfferLogic.isSaleActive(seenAt, nowSec())
        overlay = React.createElement(ExclusiveShopPanel, {
            boosts = ShopMockData.boosts({
                saleActive = saleActive,
                ownsLuckyX2 = hud.ownsLuckyX2 == true,
                ownsLuckyX4 = hud.ownsLuckyX4 == true,
            }),
            cash = ShopMockData.cash(),
            gamepasses = ShopMockData.gamepasses(),
            onBuy = function(productId: string)
                if productId == "lucky_x2" or productId == "lucky_x4" then
                    playClick()
                    if ctx.onBoostOffer then
                        ctx.onBoostOffer(productId)
                    else
                        task.spawn(function()
                            local zap = getZap()
                            if zap and zap.BuyBoostOffer then
                                zap.BuyBoostOffer.Call(productId)
                            else
                                print(`[Shop] buy {productId} (no Zap)`)
                            end
                        end)
                    end
                    return
                end
                if productId == "gp_mega_pack" then
                    playClick()
                    task.spawn(function()
                        local zap = getZap()
                        if zap and zap.BuyMegaPack then
                            zap.BuyMegaPack.Call()
                        else
                            print("[Shop] buy gp_mega_pack (no Zap)")
                        end
                    end)
                    return
                end
                if
                    productId == "cash_small"
                    or productId == "cash_simple"
                    or productId == "cash_medium"
                then
                    playClick()
                    task.spawn(function()
                        local zap = getZap()
                        if zap and zap.BuyCoinPack then
                            zap.BuyCoinPack.Call(productId)
                        else
                            print(`[Shop] buy {productId} (no Zap)`)
                        end
                    end)
                    return
                end
                print(`[Shop] unhandled buy {productId}`)
            end,
            onGift = function(_productId: string) end,
            onClose = close,
        })
    elseif open == "index" then
        local foundRaw = NetTypes.decodeJsonArray(props.indexFoundJson or "[]")
        local foundKeys: { string } = {}
        for _, key in foundRaw do
            if typeof(key) == "string" then
                table.insert(foundKeys, key)
            end
        end
        overlay = React.createElement(IndexPanel, {
            items = IndexMockData.items({ foundKeys = foundKeys }),
            onClose = close,
        })
    elseif open == "rewards" then
        overlay = React.createElement(RewardsPanel, {
            items = rewardItems,
            onClose = close,
            onClaim = handleRewardClaim,
            onSkipAll = function()
                playClick()
                task.spawn(function()
                    local zap = getZap()
                    if zap and zap.BuySkipAllRewards then
                        zap.BuySkipAllRewards.Call()
                    else
                        print("[Rewards] Skip All (no Zap)")
                    end
                end)
            end,
        })
    elseif open == "upgrades" then
        overlay = React.createElement(UpgradesPanel, {
            onClose = close,
            onBuyRobux = function(upgradeId: string)
                playClick()
                task.spawn(function()
                    local zap = getZap()
                    if zap and zap.BuyUpgradeRobux then
                        local result = zap.BuyUpgradeRobux.Call(upgradeId)
                        if not result.success then
                            print(`[Upgrades] Robux buy fail {upgradeId}: {result.error}`)
                        end
                    else
                        print(`[Upgrades] Robux buy {upgradeId} (no Zap)`)
                    end
                end)
            end,
        })
    end

    local offlineOverlay = if showOffline
        then React.createElement(OfflineEarningsPanel, {
            data = {
                headline = "While OFFLINE  you earned..",
                currentText = Formatters.money(pendingOffline),
                doubleText = Formatters.money(pendingOffline * 2),
                doublePrice = ProductIds.OfflineDoubleRobuxPrice,
            },
            onCancel = function()
                playClick()
                setOfflineDismissed(true)
                if props.onClaimOffline then
                    props.onClaimOffline()
                end
            end,
            onDouble = function()
                playClick()
                if props.onDoubleOffline then
                    props.onDoubleOffline()
                end
            end,
        })
        else nil

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = hudVisible,
    }, {
        Hud = React.createElement(HudPanel, {
            data = { coins = coins },
            giftAttention = giftAttention,
            onShop = function()
                openWindow("shop")
            end,
            onIndex = function()
                openWindow("index")
            end,
            onGift = function()
                openWindow("rewards")
            end,
            onUpgrades = function()
                openWindow("upgrades")
            end,
            onRebirth = props.onRebirth,
        }),
        BoostRail = React.createElement(BoostOffers),
        Window = if overlay
            then React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 50,
            }, {
                Panel = overlay,
            })
            else nil,
        Offline = if offlineOverlay
            then React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 55,
            }, {
                Panel = offlineOverlay,
            })
            else nil,
        FxHost = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 60,
            ref = function(rbx: Frame?)
                FxOverlay.setHost(rbx)
            end,
        }),
        Money = React.createElement(MoneyDisplay, {
            amount = coins,
        }),
    })
end

return HudShell
