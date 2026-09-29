--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)

export type Deps = {
    grantProduct: (player: Player, productId: number, purchaseId: string) -> boolean,
    grantGamepass: (player: Player, gamepassId: number, fromPurchase: boolean?) -> boolean,
}

local MonetizationManager = {}
MonetizationManager.__index = MonetizationManager

function MonetizationManager.owns(player: Player, gamepassId: number): boolean
    if typeof(gamepassId) ~= "number" or gamepassId <= 0 then
        return false
    end
    local ok, owned = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
    end)
    return ok and owned == true
end

function MonetizationManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, MonetizationManager)
end

function MonetizationManager:start()
    local deps = self._deps
    MarketplaceService.ProcessReceipt = function(receipt)
        local player = Players:GetPlayerByUserId(receipt.PlayerId)
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
        local ok = deps.grantProduct(player, receipt.ProductId, receipt.PurchaseId)
        if ok then
            Logger.info("Monetization", `granted product {receipt.ProductId} to {player.Name}`)
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(
        function(player, gamepassId, purchased)
            if purchased then
                if deps.grantGamepass(player, gamepassId, true) then
                    Logger.info("Monetization", `granted gamepass {gamepassId} to {player.Name}`)
                end
                return
            end
            -- Already owned: sync profile so pads show Owned (e.g. bought outside session).
            if MonetizationManager.owns(player, gamepassId) then
                if deps.grantGamepass(player, gamepassId, false) then
                    Logger.info(
                        "Monetization",
                        `synced owned gamepass {gamepassId} to {player.Name}`
                    )
                end
            end
        end
    )
end

function MonetizationManager.promptDevProduct(player: Player, productKey: string)
    local id = (ProductIds :: { [string]: number })[productKey]
    if typeof(id) ~= "number" or id <= 0 then
        Logger.warn("Monetization", `invalid product key {productKey}`)
        return
    end
    MarketplaceService:PromptProductPurchase(player, id)
end

return MonetizationManager
