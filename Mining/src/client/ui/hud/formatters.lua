--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpgradeLogic = require(ReplicatedStorage:WaitForChild("shared").util.UpgradeLogic)
local NumberFormat = require(ReplicatedStorage:WaitForChild("shared").util.NumberFormat)

local Formatters = {}

function Formatters.shortNumber(n: number): string
    if n >= 1e9 then
        return NumberFormat.decimal(n / 1e9, 1) .. "B"
    elseif n >= 1e6 then
        return NumberFormat.decimal(n / 1e6, 1) .. "M"
    elseif n >= 1e3 then
        return NumberFormat.decimal(n / 1e3, 1) .. "K"
    end
    return tostring(math.floor(n))
end

function Formatters.decimal(n: number, decimals: number?): string
    return NumberFormat.decimal(n, decimals)
end

function Formatters.upgradeCost(upgradeId: string, level: number): number
    return UpgradeLogic.upgradeCost(upgradeId, level)
end

return Formatters
