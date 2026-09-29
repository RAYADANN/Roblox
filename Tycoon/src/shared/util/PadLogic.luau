--!strict
-- Pure pad availability. No Roblox services.

local FarmLogic
if script and script.Parent then
    FarmLogic = require(script.Parent.FarmLogic)
else
    FarmLogic = require("./FarmLogic")
end

local PadLogic = {}

function PadLogic.buyAffordable(
    units: { number },
    qty: number,
    coins: number,
    buyCount: number,
    maxSlots: number,
    productionLevel: number?
): boolean
    local ok = FarmLogic.canBuy(units, qty, coins, buyCount, maxSlots, productionLevel)
    return ok
end

-- Face color: only money vs price (slots checked on press, not as red).
function PadLogic.buyCanPay(coins: number, buyCount: number, qty: number): boolean
    return coins >= FarmLogic.batchCost(buyCount, qty)
end

function PadLogic.mergeReady(units: { number }): boolean
    return FarmLogic.mergeTier(units) ~= nil
end

function PadLogic.upgradeAffordable(coins: number, cost: number): boolean
    return coins >= cost
end

function PadLogic.productionUpgradeReady(
    productionLevel: number,
    rebirths: number,
    buyCount: number,
    coins: number
): boolean
    local ok = FarmLogic.canUpgradeProduction(productionLevel, rebirths, buyCount, coins)
    return ok
end

return PadLogic
