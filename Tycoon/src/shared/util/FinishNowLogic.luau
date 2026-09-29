--!strict
-- Finish Now DevProduct: flush shop queue for Robux. CI-tested (Lune).

local ProductIds
if script and script.Parent then
    ProductIds = require(script.Parent.Parent.data.ProductIds)
else
    ProductIds = require("../data/ProductIds")
end

local FinishNowLogic = {}

FinishNowLogic.ROBUX = 20

function FinishNowLogic.productId(): number
    return ProductIds.FinishNow
end

function FinishNowLogic.isProduct(productId: number): boolean
    return typeof(productId) == "number" and productId == ProductIds.FinishNow and productId > 0
end

return FinishNowLogic
