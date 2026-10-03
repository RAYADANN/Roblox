--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)

export type Deps = {
    grantProduct: (player: Player, productId: number) -> boolean,
    --- Called when SkipUnpack is purchased (or Studio mock).
    onSkipUnpack: ((player: Player, slotIndex: number) -> boolean)?,
    --- Fallback if ProcessReceipt arrives without pending intent.
    findPackingSlot: ((player: Player) -> number?)?,
    --- Limited Robux stand grant (Studio mock / receipt).
    onLimitedPurchase: ((player: Player, standId: string) -> boolean)?,
    --- Shop Mega Pack → all Limited heroes (GamePass).
    onMegaPackPurchase: ((player: Player) -> boolean)?,
    --- GamePass grant dispatcher (boosts / mega).
    onGamePassPurchase: ((player: Player, gamePassId: number) -> boolean)?,
    --- Soft currency from cash DevProducts.
    onCoinPackPurchase: ((player: Player, coins: number) -> boolean)?,
    --- Timed Rewards Skip All.
    onSkipAllRewards: ((player: Player) -> boolean)?,
}

local MonetizationManager = {}
MonetizationManager.__index = MonetizationManager

type PendingSkip = { slotIndex: number }
type PendingLimited = { standId: string }

local _pendingSkip: { [number]: PendingSkip } = {}
local _pendingLimited: { [number]: PendingLimited } = {}

local COIN_PACK_BY_KEY: { [string]: { productIdKey: string, coinsKey: string } } = {
    cash_small = { productIdKey = "CoinPackSmall", coinsKey = "CoinPackSmallCoins" },
    cash_simple = { productIdKey = "CoinPackMedium", coinsKey = "CoinPackMediumCoins" },
    cash_medium = { productIdKey = "CoinPackBig", coinsKey = "CoinPackBigCoins" },
}

function MonetizationManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, MonetizationManager)
end

local function productIdOf(key: string): number
    local id = (ProductIds :: any)[key]
    return if typeof(id) == "number" then id else 0
end

function MonetizationManager:start()
    local selfAny = self :: any
    local deps = selfAny._deps
    MarketplaceService.ProcessReceipt = function(receipt)
        local player = Players:GetPlayerByUserId(receipt.PlayerId)
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
        local ok = deps.grantProduct(player, receipt.ProductId)
        if ok then
            Logger.info("Monetization", `granted product {receipt.ProductId} to {player.Name}`)
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(
        function(player, gamePassId, wasPurchased)
            if not wasPurchased then
                return
            end
            if deps.onGamePassPurchase then
                local ok = deps.onGamePassPurchase(player, gamePassId)
                if ok then
                    Logger.info("Monetization", `granted gamepass {gamePassId} to {player.Name}`)
                end
            end
        end
    )

    Players.PlayerRemoving:Connect(function(player)
        _pendingSkip[player.UserId] = nil
        _pendingLimited[player.UserId] = nil
    end)
end

function MonetizationManager.promptDevProduct(player: Player, productKey: string)
    local id = productIdOf(productKey)
    if id <= 0 then
        Logger.warn("Monetization", `invalid product key {productKey}`)
        return
    end
    MarketplaceService:PromptProductPurchase(player, id)
end

function MonetizationManager.promptGamePass(player: Player, gamePassId: number)
    if gamePassId <= 0 then
        Logger.warn("Monetization", "invalid gamepass id")
        return
    end
    MarketplaceService:PromptGamePassPurchase(player, gamePassId)
end

function MonetizationManager.takePendingSkip(userId: number): number?
    local pending = _pendingSkip[userId]
    _pendingSkip[userId] = nil
    if pending then
        return pending.slotIndex
    end
    return nil
end

function MonetizationManager.isSkipUnpackProduct(productId: number): boolean
    local id = ProductIds.SkipUnpack
    return typeof(id) == "number" and id > 0 and productId == id
end

function MonetizationManager.isSkipAllRewardsProduct(productId: number): boolean
    local id = productIdOf("SkipAllRewards")
    return id > 0 and productId == id
end

function MonetizationManager.isMegaPackGamePass(gamePassId: number): boolean
    local id = productIdOf("MegaPack")
    return id > 0 and gamePassId == id
end

function MonetizationManager.coinPackCoinsForProductId(productId: number): number?
    local packs = {
        { idKey = "CoinPackSmall", coinsKey = "CoinPackSmallCoins" },
        { idKey = "CoinPackMedium", coinsKey = "CoinPackMediumCoins" },
        { idKey = "CoinPackBig", coinsKey = "CoinPackBigCoins" },
    }
    for _, pack in packs do
        if productIdOf(pack.idKey) == productId then
            local coins = (ProductIds :: any)[pack.coinsKey]
            if typeof(coins) == "number" and coins > 0 then
                return math.floor(coins)
            end
        end
    end
    return nil
end

function MonetizationManager:resolveSkipSlot(player: Player): number?
    local deps = (self :: any)._deps
    local pending = MonetizationManager.takePendingSkip(player.UserId)
    if pending then
        return pending
    end
    if deps.findPackingSlot then
        return deps.findPackingSlot(player)
    end
    return nil
end

function MonetizationManager:grantSkipUnpack(player: Player): boolean
    local deps = (self :: any)._deps
    local slotIndex = self:resolveSkipSlot(player)
    if not slotIndex then
        Logger.warn("Monetization", `SkipUnpack: no packing slot for {player.Name}`)
        return false
    end
    if deps.onSkipUnpack then
        return deps.onSkipUnpack(player, slotIndex) == true
    end
    return false
end

--- Prompt SkipUnpack for a packing container. Studio + id=0 grants immediately.
function MonetizationManager:promptSkipUnpack(player: Player, slotIndex: number)
    local deps = (self :: any)._deps
    local idx = math.floor(slotIndex)
    if idx < 1 then
        return
    end
    _pendingSkip[player.UserId] = { slotIndex = idx }

    local id = ProductIds.SkipUnpack
    if typeof(id) ~= "number" or id <= 0 then
        if RunService:IsStudio() then
            Logger.info("Monetization", `Studio mock SkipUnpack slot={idx} for {player.Name}`)
            if deps.onSkipUnpack then
                deps.onSkipUnpack(player, idx)
            end
            _pendingSkip[player.UserId] = nil
            return
        end
        Logger.warn("Monetization", "SkipUnpack product id not set")
        _pendingSkip[player.UserId] = nil
        return
    end
    MarketplaceService:PromptProductPurchase(player, id)
end

function MonetizationManager.takePendingLimited(userId: number): string?
    local pending = _pendingLimited[userId]
    _pendingLimited[userId] = nil
    if pending then
        return pending.standId
    end
    return nil
end

function MonetizationManager:promptLimited(player: Player, standId: string)
    local deps = (self :: any)._deps
    local LimitedOfferDatabase = require(ReplicatedStorage.shared.data.LimitedOfferDatabase)
    local offer = LimitedOfferDatabase.get(standId)
    if not offer then
        Logger.warn("Monetization", `unknown Limited stand {standId}`)
        return
    end
    _pendingLimited[player.UserId] = { standId = standId }

    local id = offer.productId
    if typeof(id) ~= "number" or id <= 0 then
        if RunService:IsStudio() then
            Logger.info("Monetization", `Studio mock Limited {standId} for {player.Name}`)
            if deps.onLimitedPurchase then
                deps.onLimitedPurchase(player, standId)
            end
            _pendingLimited[player.UserId] = nil
            return
        end
        Logger.warn("Monetization", `Limited product id not set for {standId}`)
        _pendingLimited[player.UserId] = nil
        return
    end
    MarketplaceService:PromptProductPurchase(player, id)
end

function MonetizationManager:grantLimitedFromReceipt(player: Player, productId: number): boolean
    local deps = (self :: any)._deps
    local LimitedOfferDatabase = require(ReplicatedStorage.shared.data.LimitedOfferDatabase)
    local pendingStand = MonetizationManager.takePendingLimited(player.UserId)
    local offer = if pendingStand
        then LimitedOfferDatabase.get(pendingStand)
        else LimitedOfferDatabase.getByProductId(productId)
    if not offer then
        offer = LimitedOfferDatabase.getByProductId(productId)
    end
    if not offer then
        return false
    end
    if deps.onLimitedPurchase then
        return deps.onLimitedPurchase(player, offer.standId) == true
    end
    return false
end

--- Shop Mega Pack prompt (GamePass).
function MonetizationManager:promptMegaPack(player: Player)
    local deps = (self :: any)._deps
    local id = productIdOf("MegaPack")
    if id <= 0 then
        if RunService:IsStudio() then
            Logger.info("Monetization", `Studio mock MegaPack for {player.Name}`)
            if deps.onMegaPackPurchase then
                deps.onMegaPackPurchase(player)
            end
            return
        end
        Logger.warn("Monetization", "MegaPack gamepass id not set")
        return
    end
    MarketplaceService:PromptGamePassPurchase(player, id)
end

function MonetizationManager:promptSkipAllRewards(player: Player)
    local deps = (self :: any)._deps
    local id = productIdOf("SkipAllRewards")
    if id <= 0 then
        if RunService:IsStudio() then
            Logger.info("Monetization", `Studio mock SkipAllRewards for {player.Name}`)
            if deps.onSkipAllRewards then
                deps.onSkipAllRewards(player)
            end
            return
        end
        Logger.warn("Monetization", "SkipAllRewards product id not set")
        return
    end
    MarketplaceService:PromptProductPurchase(player, id)
end

function MonetizationManager:promptCoinPack(player: Player, packId: string): (boolean, string?)
    local mapping = COIN_PACK_BY_KEY[packId]
    if not mapping then
        return false, "unknown_pack"
    end
    local id = productIdOf(mapping.productIdKey)
    local coins = (ProductIds :: any)[mapping.coinsKey]
    if typeof(id) ~= "number" or id <= 0 then
        if RunService:IsStudio() and typeof(coins) == "number" and coins > 0 then
            Logger.info("Monetization", `Studio mock coin pack {packId} for {player.Name}`)
            local deps = (self :: any)._deps
            if deps.onCoinPackPurchase then
                deps.onCoinPackPurchase(player, math.floor(coins))
            end
            return true, nil
        end
        return false, "product_unset"
    end
    MarketplaceService:PromptProductPurchase(player, id)
    return true, nil
end

function MonetizationManager:grantCoinPackFromReceipt(player: Player, productId: number): boolean
    local coins = MonetizationManager.coinPackCoinsForProductId(productId)
    if not coins then
        return false
    end
    local deps = (self :: any)._deps
    if deps.onCoinPackPurchase then
        return deps.onCoinPackPurchase(player, coins) == true
    end
    return false
end

function MonetizationManager:grantSkipAllFromReceipt(player: Player, productId: number): boolean
    if not MonetizationManager.isSkipAllRewardsProduct(productId) then
        return false
    end
    local deps = (self :: any)._deps
    if deps.onSkipAllRewards then
        return deps.onSkipAllRewards(player) == true
    end
    return false
end

--- Re-apply owned boost GamePasses into profile (join / rejoin).
--- MegaPack is grant-once on purchase (not re-synced — would duplicate Limited heroes).
function MonetizationManager:syncGamePasses(player: Player)
    local deps = (self :: any)._deps
    if not deps.onGamePassPurchase then
        return
    end
    local ids = {
        productIdOf("LuckyX2"),
        productIdOf("LuckyX4"),
        productIdOf("MoneyX2Gold"),
    }
    for _, id in ids do
        if id > 0 then
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
            end)
            if ok and owns == true then
                deps.onGamePassPurchase(player, id)
            end
        end
    end
end

return MonetizationManager
