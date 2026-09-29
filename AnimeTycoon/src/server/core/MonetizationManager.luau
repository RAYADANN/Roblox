--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)

export type Deps = {
    grantProduct: (player: Player, productId: number) -> boolean,
}

local MonetizationManager = {}
MonetizationManager.__index = MonetizationManager

function MonetizationManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, MonetizationManager)
end

function MonetizationManager:start()
    local deps = self._deps
    MarketplaceService.ProcessReceipt = function(receipt)
        local player = game:GetService("Players"):GetPlayerByUserId(receipt.PlayerId)
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
end

function MonetizationManager.promptDevProduct(player: Player, productKey: string)
    local id = ProductIds[productKey]
    if typeof(id) ~= "number" or id <= 0 then
        Logger.warn("Monetization", `invalid product key {productKey}`)
        return
    end
    MarketplaceService:PromptProductPurchase(player, id)
end

return MonetizationManager
